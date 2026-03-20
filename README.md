🛒 Online Retail Data Analysis (SQL Project)


📌 Project Overview

This project analyzes an online retail transaction dataset using SQL to uncover insights about product performance, revenue product analysis and customer behavior. The dataset contains over 500,000 transactions, including product purchases, customer IDs, timestamps, and pricing information.
The main goal of this project is to demonstrate data cleaning, SQL querying, and business insight generation from real-world retail data.


🧰 Tools Used

MySQL, Python, Tableau (for visualization/dashboard), ChatGPT, Claude, Gemini


📂 Dataset

Dataset: Online Retail Dataset (https://www.kaggle.com/datasets/vijayuv/onlineretail)

The dataset contains:
InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country (8 columns)
Due to messy real-world data, the dataset required extensive data cleaning before analysis.


🧹 Data Cleaning Process

Several preprocessing steps were applied to ensure accurate analysis:
1. Removed duplicate transactions using ROW_NUMBER() window function
2. Converted date strings to SQL datetime using STR_TO_DATE()
3. Handled missing values and empty strings
4. Standardized text fields using TRIM() and REPLACE()
5. Removed invalid transactions such as:
   - returns (InvoiceNo LIKE 'C%')
   - negative quantities
   - adjustments and damaged products
6. Filtered the dataset to focus on United Kingdom transactions
7. Created a calculated column TotalSales = Quantity × UnitPrice


📊 Key Metrics

The following business KPIs were calculated:

💰 Total Revenue

🧾 Total Orders

👥 Unique Customers

🔁 Repeat Customer Rate

These metrics help measure overall business performance and customer loyalty.


🔍 Analysis Areas

📦 Product Performance

1. Identified Top 10 Bestselling Products
2. Identified Top 10 Revenue Generating Products
   
Insight:
A small number of products account for a large portion of sales volume and revenue.


⏰ Sales Time Patterns

1. Analyzed Sales by Hour
2. Analyzed Sales by Day of Week
   
Insight:
Sales peak around 10 AM, 12 PM, and 3 PM, while Tuesday shows the highest purchase activity.


💡 Business Recommendations

Based on the analysis:

- Prioritize inventory for best-selling products
- Promote high-revenue products to increase profitability
- Schedule promotions during peak sales hours
- Launch campaigns earlier in the week to leverage Tuesday demand
