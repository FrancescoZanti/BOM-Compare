using System;
using System.Data;
using System.Data.SqlClient;
using System.Windows.Forms;
using ClosedXML.Excel;

namespace BOM_Compare
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private string GetConnectionString()
        {
            return "Data Source=localhost;Initial Catalog=AdventureWorks;Integrated Security=True";
        }

        private void groupBox1_Enter(object sender, EventArgs e)
        {
            using (SqlConnection connection = new SqlConnection(GetConnectionString()))
            {
                connection.Open();
                using (SqlCommand command = new SqlCommand("dbo.uspCompareBillOfMaterials", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@StartProductID_1", textBox1.Text);
                    command.Parameters.AddWithValue("@StartProductID_2", textBox2.Text);
                    command.Parameters.AddWithValue("@CheckDate", DateTime.Now);
                    using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                    {
                        DataTable table = new DataTable();
                        adapter.Fill(table);
                        // Ordina i dati per la colonna "Stato"
                        table.DefaultView.Sort = "Outcome";
                        dataGridView1.DataSource = table;
                        // Coloro le righe in base al valore della colonna "STATO"
                        foreach (DataGridViewRow row in dataGridView1.Rows)
                        {
                            if (row.Cells["Outcome"].Value.ToString() == "0. Nothing change")
                            {
                                row.DefaultCellStyle.BackColor = System.Drawing.Color.LightYellow;
                            }
                            else if (row.Cells["Outcome"].Value.ToString() == "1. Added")
                            {
                                row.DefaultCellStyle.BackColor = System.Drawing.Color.LightGreen;
                            }
                            else if (row.Cells["Outcome"].Value.ToString() == "2. Deleted")
                            {
                                row.DefaultCellStyle.BackColor = System.Drawing.Color.LightCoral;
                            }
                            else if (row.Cells["Outcome"].Value.ToString() == "3. Qty Modified")
                            {
                                row.DefaultCellStyle.BackColor = System.Drawing.Color.LightBlue;
                            }
                        }
                    }
                }
            }

            esporta_excel();

        }

        public void esporta_excel()
        {
            // Esporta i risultati in un file Excel nella cartella C:\temp con OpenXML

            SaveFileDialog saveFileDialog = new SaveFileDialog();
            saveFileDialog.Filter = "Excel files (*.xlsx)|*.xlsx";
            saveFileDialog.Title = "Save an Excel File";
            saveFileDialog.FileName = "BOM_Compare_BT" + " - " + DateTime.Now.ToString("yyyyMMdd") + ".xlsx";
            saveFileDialog.InitialDirectory = @"C:\temp";

            if (saveFileDialog.ShowDialog() == DialogResult.OK)
            {
                using (XLWorkbook workbook = new XLWorkbook())
                {
                    workbook.Worksheets.Add(dataGridView1.DataSource as DataTable, "BOM_Compare_BT");
                    // Allargo le colonne per far vedere tutto il contenuto
                    workbook.Worksheet(1).Columns().AdjustToContents();
                    workbook.SaveAs(saveFileDialog.FileName);
                }
            }
        }
    }
}
