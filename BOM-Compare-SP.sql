USE [AdventureWorks]
GO

/****** Object:  StoredProcedure [dbo].[uspCompareBillOfMaterials]    Script Date: 10/08/2024 16:27:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Francesco Zanti>
-- Create date: <2024-08-08>
-- Description:	<Compare BOMs>
-- =============================================

CREATE PROCEDURE [dbo].[uspCompareBillOfMaterials]
    @StartProductID_1 [int],
	@StartProductID_2 [int],
    @CheckDate [datetime] 
AS
BEGIN
    SET NOCOUNT ON;

	SET @CheckDate = GETDATE();


	-- EXEC [dbo].[uspCompareBillOfMaterials] 788, 789, '2024-01-01T00:00:00.000'

    -- Use recursive query to generate a multi-level Bill of Material (i.e. all level 1 
    -- components of a level 0 assembly, all level 2 components of a level 1 assembly)
    -- The CheckDate eliminates any components that are no longer used in the product on this date.
    WITH [BOM_cte_1]([ProductAssemblyID], [ComponentID], [ComponentDesc], [PerAssemblyQty], [StandardCost], [ListPrice], [BOMLevel], [RecursionLevel]) -- CTE name and columns
    AS (
        SELECT b.[ProductAssemblyID], b.[ComponentID], p.[Name], b.[PerAssemblyQty], p.[StandardCost], p.[ListPrice], b.[BOMLevel], 0 -- Get the initial list of components for the bike assembly
        FROM [Production].[BillOfMaterials] b
            INNER JOIN [Production].[Product] p 
            ON b.[ComponentID] = p.[ProductID] 
        WHERE b.[ProductAssemblyID] = @StartProductID_1 
            AND @CheckDate >= b.[StartDate] 
            AND @CheckDate <= ISNULL(b.[EndDate], @CheckDate)
        UNION ALL
        SELECT b.[ProductAssemblyID], b.[ComponentID], p.[Name], b.[PerAssemblyQty], p.[StandardCost], p.[ListPrice], b.[BOMLevel], [RecursionLevel] + 1 -- Join recursive member to anchor
        FROM [BOM_cte_1] cte
            INNER JOIN [Production].[BillOfMaterials] b 
            ON b.[ProductAssemblyID] = cte.[ComponentID]
            INNER JOIN [Production].[Product] p 
            ON b.[ComponentID] = p.[ProductID] 
        WHERE @CheckDate >= b.[StartDate] 
            AND @CheckDate <= ISNULL(b.[EndDate], @CheckDate)
        ),

		[BOM_cte_2]([ProductAssemblyID], [ComponentID], [ComponentDesc], [PerAssemblyQty], [StandardCost], [ListPrice], [BOMLevel], [RecursionLevel]) -- CTE name and columns
    AS (
        SELECT b.[ProductAssemblyID], b.[ComponentID], p.[Name], b.[PerAssemblyQty], p.[StandardCost], p.[ListPrice], b.[BOMLevel], 0 -- Get the initial list of components for the bike assembly
        FROM [Production].[BillOfMaterials] b
            INNER JOIN [Production].[Product] p 
            ON b.[ComponentID] = p.[ProductID] 
        WHERE b.[ProductAssemblyID] = @StartProductID_2 
            AND @CheckDate >= b.[StartDate] 
            AND @CheckDate <= ISNULL(b.[EndDate], @CheckDate)
        UNION ALL
        SELECT b.[ProductAssemblyID], b.[ComponentID], p.[Name], b.[PerAssemblyQty], p.[StandardCost], p.[ListPrice], b.[BOMLevel], [RecursionLevel] + 1 -- Join recursive member to anchor
        FROM [BOM_cte_2] cte
            INNER JOIN [Production].[BillOfMaterials] b 
            ON b.[ProductAssemblyID] = cte.[ComponentID]
            INNER JOIN [Production].[Product] p 
            ON b.[ComponentID] = p.[ProductID] 
        WHERE @CheckDate >= b.[StartDate] 
            AND @CheckDate <= ISNULL(b.[EndDate], @CheckDate)
        )

    -- Outer select from the CTE
	SELECT 


	CASE 

	WHEN b1.ComponentID IS NULL AND b2.ComponentID IS NOT NULL THEN '1. Added'
	WHEN b1.ComponentID IS NOT NULL AND b2.ComponentID IS NULL THEN '2. Deleted'
	WHEN b1.PerAssemblyQty <> b2.PerAssemblyQty THEN '3. Qty Modified'
	ELSE '0. Nothing change' 

	END AS Outcome,


	b1.ProductAssemblyID AS AssID_1,
	b1.ComponentID AS CompID_1,
	b1.ComponentDesc AS CompDesc_1,
	b1.PerAssemblyQty AS Qty_1,
	b1.BOMLevel AS Level_1,

	b2.ProductAssemblyID AS AssID_2,
	b2.ComponentID AS CompID_2,
	b2.ComponentDesc AS CompDesc_2,
	b2.PerAssemblyQty AS Qty_2,
	b2.BOMLevel AS Level_2


    FROM [BOM_cte_1] b1

	LEFT JOIN [BOM_cte_2] b2
	ON b1.ComponentID = b2.ComponentID


    -- ORDER BY b1.[BOMLevel], b1.[ProductAssemblyID], b1.[ComponentID]
    
END;
GO

