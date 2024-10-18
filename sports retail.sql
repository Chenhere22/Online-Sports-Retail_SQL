--1. Data preparation

-- We have five tables: brands, finance, info, reviews and traffic. When upload the five tables on Snowflake warehouse, I set the column names and modify the data type
--reset brands, info and reviews tables
--change the data type of last_visited as timestamp_ntz.

-- 2. Tasks
--2.1 Please count missing data in each table

SELECT COUNT(*) as total_row,
       COUNT(i.description) AS count_description,
       COUNT(f.listing_price) AS count_listing_price,
       COUNT(t.last_visited) AS count_last_visited,
       COUNT(r.reviews) AS count_reviews
FROM info1 AS i
JOIN finance AS f ON i.product_id = f.product_id
JOIN traffic AS t ON i.product_id = t.product_id
LEFT JOIN reviews AS r ON t.product_id = r.product_id;
--Data insights: missing values in info, finance and traffic tables. 

--2.2 Compare Nike vs. Adidas pricing
SELECT  b.brand, f.listing_price, COUNT(f.*) AS Amount
FROM finance f
JOIN brands b ON b.product_id = f.product_id
GROUP BY b.brand, f.listing_price
ORDER BY f.listing_price DESC;
-- Data insights: We can find Adidas has wider pricing range from 9 to 300, compared to Nike from 30 to 200.
-- Business insights: see below

--2.3 Label price ranges
SELECT b.brand, COUNT(f.*), ROUND(SUM(f.revenue)) AS total_revenue
CASE WHEN f.listing_price < 42 THEN 'Budget'
     WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
     WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive' 
     ELSE 'Elite' 
     END AS listing_price_category
FROM finance f
JOIN brands b ON f.product_id = b.product_id
GROUP BY b.brand, listing_price_category
ORDER BY total_revenue DESC;

-- Data insights: Adidas offers a wider range of products, with the 'Average' price category being the most common. In contrast, Nike has fewer products, with 'Budget' as its leading price category. While Adidas primarily focuses on 'Average' and higher price points, Nike emphasizes 'Budget' options. Both brands generate the highest revenue from the 'Elite' price category, although the number of products in this category is the least or second least for both brands. Additionally, Adidas performs better in revenue within the 'Elite' segment compared to Nike.
--Business insigts: Offering a wider range of product types can satisfy diverse customer preferences, potentially leading to increased overall sales and revenue.  Each pricing category should reflect the perceived value of the products, aligning with customer expectations and willingness to pay. Analyzing the customer demographics for both brands can clarify why Adidas commands higher prices, as it targets consumers who prioritize quality over cost.

--2.4 Calculate average discount by brand
SELECT b.brand, AVG(f.discount) *100 AS average_discount
FROM brands b
JOIN finance f ON b.product_id = f.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand
-- Adidas has 33.45% average discount whereas Nike has 0 average discount.
-- Business insights: The discount is a promotion pricing strategy, The higher discount will attract more targeted customers, but it might harm the reputation of brand. The pricing of Adidas is higher and the discount will satisfy their tager markets' needs. Nike provides much less discount. This can keep their sales stable and might protect their brand reputation. The influence of discount should be further to analyse discount range and KPIs.

--2.5 Analyze correlation between revenue and reviews
SELECT CORR(f.revenue, r.reviews) AS revenue_review_correlation
FROM finance f
JOIN reviews r ON f.product_id = r.product_id;
-- Data insight: The correlation between review and revenue is 0.65
-- Business insight: Actively encouraging customers to leave reviews can enhance product visibility and credibility, potentially boosting sales and revenue.Use reviews in marketing strategies to highlight positive customer experiences, leveraging social proof to attract new customers.  Identify products with a high number of reviews but lower sales, indicating a potential disconnect that could be addressed through targeted promotions or improved marketing efforts.
--IT insights: Utilize advanced analytics tools to assess the impact of reviews on sales, enabling real-time insights into customer sentiment and trends that can inform business decisions. Integrate the review system with Customer Relationship Management (CRM) tools to capture customer interactions and feedback, providing a comprehensive view of customer behavior and preferences.

--2.6 Evaluate ratings and reviews based on product description length
SELECT TRUNC(LENGTH(i.description) / 100.0) *100 AS descrition_lenght, ROUND(AVG(r.rating) AS average_rating, COUNT(r.reviews) AS total_reviews
FROM info i
JOIN reviews r ON i.product_id = r.product_id
WHERE i.description IS NOT NULL
GROUP BY description_length
ORDER BY description_length;
-- Data insight: Analysis shows that, in general, the longer the product description, the higher the average rating. Specifically, products with descriptions around 600 characters have the highest average rating of 3.65. However, descriptions in the 500-character range see a dip, ranking as the second lowest in ratings.
--Business Insight: A well-crafted product description helps customers better understand the product, and the ideal length seems to be between 300 and 600 characters. While true enthusiasts of a product may appreciate more detailed descriptions, keeping the length within this range provides sufficient information to most customers while maintaining their engagement. Other factors, such as the product's complexity, customer familiarity, and price, may influence the optimal description length. For sports retail products, this data and common sense suggest that descriptions within this range work best.

--2.7 Track reviews by month and brand
SELECT b.brand, CAST(DATE_PART('month', t.last_visited) AS INTEGER) AS month, COUNT(DISTINCT r.reviews) AS review_amount
FROM brands b
INNER JOIN traffic t ON b.product_id = t.product_id
INNER JOIN reviews r ON r.product_id = b.product_id
GROUP BY b.brand, month
ORDER BY b.brand, month;
-- Data insights Adidas receives a significantly higher number of reviews from January to March, peaking at 272 reviews in February and dipping to 150 reviews in November. Similarly, Nike experiences a higher volume of reviews in the first three months of the year, with 55 reviews in March, its peak, and 28 reviews in September, its lowest. Adidas consistently attracts more reviews than Nike, indicating stronger customer engagement.
-- Business insights: Customer reviews and ratings play a crucial role in word-of-mouth marketing. The high volume of reviews suggests that Adidas has better customer engagement compared to Nike.Review management is a vital strategy for online marketing. Both brands should actively manage customer reviews to boost their online presence and attract more potential customers. Nike should focus on encouraging its customers to leave more reviews, which can help improve product visibility and sales.
--IT insights: Website traffic experiences a surge in the first quarter, aligning with a spike in customer reviews. IT infrastructure should be scaled up during this period to accommodate the increased demand, ensuring smooth website performance and minimizing downtime.

--2.8 Top 10 Revenue Generated Products with Brands
WITH highest_revenue_product AS
(SELECT i.product_name, b.brand, f.revenue
FROM finance f 
INNER JOIN info i ON i.product_id = f.product_id
INNER JOIN brands b ON b.product_id = i.product_id)

SELECT *, ROW_NUMBER() OVER (ORDER BY DESC) AS product_rank
FROM highest_revenue_product
LIMIT 10;

-- Data insights: The product with the highest revenue is Nike's Air Jordan 10 Retro, generating nearly twice the revenue of the second-ranked item. The remaining nine products are from Adidas, with the Unisex Originals Craig Green Kontuur leading in revenue for Adidas. Notably, all top 10 products are shoes.
--Business insights: Star products significantly boost revenue, suggesting that the sports industry should focus on creating standout products. Developing product lines can help capture niche market segments, making it essential for major sports companies to invest in product series. The footwear market, in particular, offers substantial revenue opportunities for sports brands.
--IT insights: Use AI and machine learning models to predict demand for high-revenue products like shoes. This can improve inventory management, reduce stockouts, and optimize supply chain efficiency.

--2.9 Assess footwear product performance
WITH footwear AS(
SELECT i.description, f.revenue
FROM info i 
JOIN finance f ON i.product_id = f.product_id
WHERE (i.description ILIKE '%shoe%' OR
i.description ILIKE '%foot%' OR
i.description ILIKE '%trainer%') AND
f.description IS NOT NULL
)

SELECT COUNT(*) AS num_footwear, MEDIAN(f.revenue) AS median_footwear_revenue
FROM footwear;
-- Data insights: Out of 3,117 products, 2,700 are footwear. The median revenue for footwear is over $3,000.
--Business insigts: Focus marketing campaigns on key footwear segments, emphasizing sports and lifestyle shoes, and target high-demand demographics such as athletes, fitness enthusiasts, and young professionals.  Collaborate with R&D teams to innovate new footwear designs, leveraging trends in performance, sustainability, and fashion.
--IT insights:Optimize e-commerce platforms for footwear sales, integrating features such as virtual try-on technology, personalized recommendations, and fast checkout experiences. Implement or upgrade CRM systems to better track customer interactions and feedback on footwear purchases, offering personalized marketing and post-purchase support. IT deparment updates Customer Relationship Management

--2.10 Assess clothing product performance

SELECT COUNT(i.*) AS num_clothing, MEDIAN (f.revenue) AS meidan_clothing_revenue
FROM info i
INNER JOIN finance f ON i.product_id = f.product_id
WHERE i.description NOT IN (SELECT i.description FROM footwear)

--Data insigts: There are 417 clothing products, with a median revenue of approximately $500.
--Business insights: Reduce investment in clothing lines, focusing instead on higher-performing product categories like footwear. Evaluate the clothing range and identify best-selling items, potentially phasing out underperforming products. Use limited-time promotions or discounts on clothing to clear excess inventory and attract price-sensitive customers without heavily investing in long-term marketing campaigns. 
--IT insights: Utilize data analytics to assess clothing sales trends, customer preferences, and seasonal demand patterns, helping to inform product development and inventory decisions. Develop robust systems for collecting and analyzing customer feedback on clothing purchases, enabling more informed decisions about future product offerings.