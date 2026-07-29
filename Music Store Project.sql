select * from chinook;

use chinook;

-- Index Performance
create index idx_invoice_customerId on Invoice(Customerid);
create index idx_invoiceline_invoiceId on Invoiceline(InvoiceId);
create index idx_invoiceline_trackId on Invoiceline(TrackId);
create index idx_track_alblumId on Track(AlbumId);
create index idx_album_artistId on Album(ArtistId);
create index idx_customer_supportrepid on Customer(SupportrepId);
create index idx_invoice_invoicedate on Invoice(Invoicedate);

-- Top Performing Products (Tracks\Albums) - Top 10 Tracks by Revenue 
select
    t.Trackid,
	t.Name as TrackName,
    ar.Name as ArtistName,
	al.Title as AlbumTitle,
count(il.invoicelineid) as PurchaseCount,
sum(il.UnitPrice*il.Quantity) as TotalRevenue,
round(AVG(il.unitprice),2) as AvgPrice
from Track t
inner join Album al on t.AlbumId=al.AlbumId
inner join Artist ar on al.ArtistId=ar.ArtistId
inner join Invoiceline il on t.TrackId=il.TrackId
Group by t.TrackId, T.Name, Ar.Name, Al.title
order by TotalRevenue desc
limit 10;

-- Top Albums by Revenue
With AlbumRevenue as (
     select 
		al.AlbumId,
        al.Title,
        ar.Name as Artist,
        Sum(il.UnitPrice * il.Quantity) as Revenue,
        count(Distinct i.InvoiceId) as UniqueCustomers
  from Album al
  join Artist ar on al.ArtistId = ar.ArtistId
  join Track t on al.AlbumId = t.Albumid
  join InvoiceLine il on t.TrackId = il.TrackId
  join Invoice i on il.InvoiceId = i.InvoiceId
  Group by al.AlbumId, al.Title,ar.Name
)
select
*,
Rank() over (order by Revenue desc) as RevenueRank,
Round(Revenue / sum(Revenue) over () * 100,2) as RevenuePct
from AlbumRevenue
order by Revenue desc
limit 10;

-- Top Performing Customers - Top 10 Customers by Total Spend
select
     c.CustomerId,
     concat(c.FirstName,' ', c.LastName) as CustomerName,
     c.Country,
     count(distinct i.InvoiceId) as NumInvoices,
     sum(i.Total) as TotalSpent,
     max(i.InvoiceDate) as LastPurchase
from Customer c
inner join Invoice i on c.CustomerId =i.CustomerId
group by c.CustomerId, c.FirstName,c.LastName,c.Country
order by TotalSpent desc
limit 10;

-- Customers by Spending Tier (Using NTILE)
with CustomerSpend as (
    select
        c.CustomerId,
        concat(c.FirstName,' ',c.LastName) as CustomerName,
        sum(i.Total) as TotalSpent
	from Customer c
    join Invoice i on c.CustomerId = i.CustomerId
    Group by c.CustomerId, c.FirstName,c.LastName
)
select
*,
NTILE(4) over (order by TotalSpent desc) as SpendingTier
from CustomerSpend
order by TotalSpent desc;

-- Customer Purchasing Behaviour - Monthly Revenue Trend
select
     Date_format(InvoiceDate, '%Y-%m') as Month,
     count(distinct InvoiceId) as Numorders,
     Sum(Total) as MonthlyRevenue,
     Round(sum(Total)/Count(Distinct InvoiceId),2) as AvgOrderValue
from Invoice
group by date_format(InvoiceDate, '%Y-%m')
order by Month;

-- Customer Purchase Frequency & Recency
select
     c.CustomerId,
     concat(c.FirstName,' ',c.LastName) as CustomerName,
     count(distinct i.InvoiceId) as PurchaseFrequency,
     Datediff(curdate(), max(i.InvoiceDate)) as DaysSinceLastPurchase,
     sum(i.Total) as LifetimeValue
from Customer c
left join Invoice i on c.CustomerId = i.CustomerId
group by c.CustomerId, c.FirstName,c.LastName
Having PurchaseFrequency >=2
order by LifetimeValue Desc; 

--  Genre Preferences by Country (Top Genres Per Country)
with CountryGenre as (
select
    c.Country,
    g.Name as Genre,
    sum(il.UnitPrice * il.Quantity) as GenreRevenue,
    Row_Number() over (partition by c.Country order by Sum(il.UnitPrice * il.Quantity) desc) as rn
from Customer c
join Invoice i on c.CustomerId = i.CustomerId
join InvoiceLine il on i.InvoiceId = il.InvoiceId
join Track t on il.TrackId = t.TrackId
Join Genre g on t.GenreId = g.GenreId
group by c.Country, g.Name
)
select Country, Genre, GenreRevenue
from CountryGenre
where rn <=2
order by Country,rn;

-- Cross-Sell:Tracks Bought Together (with Artist Names)
select
    t1.Name as Track1,
    ar1.Name as Artist1,
    t2.Name as Track2,
    ar2.Name as Artist2,
    count(*) as CoPurchaseCount
from InvoiceLine il1
join InvoiceLine il2 on il1.InvoiceId = il2.InvoiceId 
    and il1.TrackId < il2.TrackId
join Track t1 on il1.TrackId = t1.TrackId
join Album al1 on t1.AlbumId = al1.AlbumId
join Artist ar1 on al1.ArtistId = ar1.ArtistId
join Track t2 on il2.TrackId = t2.TrackId
join Album al2 on t2.AlbumId = al2.AlbumId
join Artist ar2 on al2.ArtistId = ar2.ArtistId
group by t1.Name, ar1.Name, t2.Name, ar2.Name
having CoPurchaseCount >= 1
order by CopurchaseCount desc
limit 30;

-- Top Revenue Per Customer
select
   i.InvoiceId,
   Concat(c.FirstName,' ',c.LastName) as Customer,
   i.InvoiceDate,
   i.Total,
   sum(i.Total) over (partition by c.CustomerId order by i.InvoiceDate) as RunningTotal
from Invoice i
join Customer c on i.CustomerId = c.CustomerId
order by c.CustomerId, i.InvoiceDate;

-- Year-over-Year Growth
with YearlyRevenue as (
    select
       Year(InvoiceDate) as Year,
       sum(Total) as Revenue
	from Invoice
    group by year(InvoiceDate)
)
select
   Year,
   Revenue,
   lag(Revenue) over (order by Year) as PrevYearRevenue,
   round((Revenue - lag(Revenue) over (order by Year)) / lag(Revenue) over (order by Year) * 100.2) as YoYGrowthPct
from YearlyRevenue
order by Year;

--  Monthly Revenue Trend & Growth
select
    date_format(InvoiceDate, '%Y-%m') as Month,
    count(distinct InvoiceId) as NumOrders,
    sum(Total) as MonthlyRevenue,
    Round(Avg(Total), 2) as AvgOrdersValue,
    Round(sum(Total) * 100.0 /sum(sum(Total)) over (),2) as RevenueSharepct
from Invoice
group by Date_format(InvoiceDate,'%Y-%m')
order by Month;

-- Top Artists by Revenue
select
    ar.Name as Artist,
    Count(distinct i.InvoiceId) as TimesSold,
    sum(il.UnitPrice * il.Quantity) as TotalRevenue,
    Round(sum(il.UnitPrice * il.Quantity) * 100.0 / sum(sum(il.UnitPrice * Quantity)) over (), 2) as RevenuePercentage
from Artist ar
join Album al on ar.ArtistId = al.ArtistId
join Track t on al.AlbumId = t.AlbumId
join InvoiceLine il on t.TrackId = il.TrackId
join Invoice i on il.InvoiceId = i.InvoiceId
group by ar.ArtistId, ar.Name
order by TotalRevenue desc
limit 15;

-- Customer Segmentation (RFM Analysis-SImplified)
with CUstomerRFM as (
select
     c.CustomerId,
     concat(c.FirstName,' ',c.LastName) as CustomerName,
     count(distinct i.InvoiceId) as Frequency,
     datediff(curdate(), max(i.InvoiceDate)) as Recency_Days,
     sum(i.Total) as Monetary
from Customer c
left join Invoice i on c.CustomerId = i.CustomerId
group by c.CustomerId,c.FirstName,c.LastName
)
select
    *,
    ntile(5) over (order by Recency_Days) as Recency_Score, 
	ntile(5) over (order by Frequency desc) as Frequency_Score,
	ntile (5) over (order by Monetary desc) as Monetary_Score
from CustomerRFM
order by Monetary desc;

-- Best Selling Media Types
select
	mt.Name as MediaType,
    count(il.InvoiceLineId) as UnitsSold,
    sum(il.UnitPrice * il.Quantity) as Revenue,
    round(Avg(il.UnitPrice),2) as AvgPrice
from MediaType mt
join Track t on mt.MediaTypeId = t.MediaTypeId
join InvoiceLine il on t.TrackId = il.TrackId
group by mt.MediaTypeId, mt.Name
order by Revenue desc;

-- PlayList Performance (most Popular Playlists)
select
     p.Name as PlaylistName,
     count(pt.TrackId) as TracksInPlaylist,
     count(distinct il.InvoiceId) as TimesPurchased,
     sum(il.UnitPrice * il.Quantity) as RevenueFromPlaylist
	from Playlist p
    join PlaylistTrack pt on p.PlaylistId = pt.PlaylistId
    join InvoiceLine il on Pt.TrackId = il.TrackId
    group by p.PlaylistId,p.Name
    order by RevenueFromPlaylist desc
    limit 10;