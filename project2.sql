create table housing_port as select * from housing_portfolio; -- copy
--
alter table housing_portfolio
rename column uniqueID_ to uniqueID;
--
select * from housing_portfolio where propertyAddress = '2524 VAL MARIE DR, MADISON';
update housing_portfolio
set propertyAddress = '2524 VAL MARIE DR, MADISON'
where propertyAddress = '2524  VAL MARIE DR, MADISON' or propertyAddress = '2524 VAL MARIE  DR, MADISON';
--
select * from housing_portfolio;
select * from housing_portfolio where rownum<=10;

select * from housing_portfolio
fetch first 10 rows only;

/*

Cleaning Data in SQL Queries

*/

select *
from housing_portfolio;

--------------------------------------------------------------------------------

-- Standardize Date Format
desc housing_portfolio;

select saledate
from housing_portfolio;

update housing_portfolio sd
set sd.saledate = cast(sd.saledate as date);


--------------------------------------------------------------------------------
-- Populate Property Address data
select * from housing_portfolio;

select parcelID, propertyAddress from housing_portfolio where parcelID in
(select parcelID from housing_portfolio where propertyAddress is null) order by parcelID, propertyAddress;

select a.parcelID, a.propertyAddress, b.parcelID, b.propertyAddress, coalesce(a.propertyAddress, b.propertyAddress) from housing_portfolio a
join housing_portfolio b
    on a.parcelID = b.parcelID and a.uniqueID != b.uniqueID
where a.propertyAddress is null;

update housing_portfolio hp
set hp.propertyAddress = (
    select src.propertyAddress
    from (
        select parcelID, propertyAddress, row_number() over (partition by parcelID order by rowid) rn
        from housing_portfolio
        where propertyAddress IS not null
    ) src
    where rn = 1
    and hp.parcelID = src.parcelID
)
where hp.propertyAddress is null;


--------------------------------------------------------------------------------
-- Breaking Out Address into Individual Columns (Address, City, State)
select
    substr(propertyAddress, 1, instr(propertyAddress, ',')-1) as address,
    substr(propertyAddress, instr(propertyAddress, ',')+1, length(propertyAddress)) as city
from housing_portfolio order by address;

alter table housing_portfolio
add PropertySplitAddress varchar2(255);

update housing_portfolio hp
set PropertySplitAddress = (
    select substr(propertyAddress, 1, instr(propertyAddress, ',') - 1)
    from housing_portfolio
    where hp.uniqueID = housing_portfolio.uniqueID
);


alter table housing_portfolio
add PropertySplitCity varchar2(255);

update housing_portfolio hp
set PropertySplitCity = (
    select substr(propertyAddress, instr(propertyAddress, ',')+1, length(propertyAddress))
    from housing_portfolio
    where hp.uniqueID = housing_portfolio.uniqueID
);

select * from housing_portfolio;

--------------------------------------------------------------------------------
-- Change Y and N to Yes and No in 'Sold as Vacant' field
select distinct(SoldAsVacant), count(*)
from housing_portfolio group by SoldAsVacant;

-- First Method:
--update h_p
--set h_p.SoldAsVacant = 'Yes' where lower(h_p.SoldAsVacant) = 'y';
--
--update h_p
--set h_p.SoldAsVacant = 'No' where lower(h_p.SoldAsVacant) = 'n';

-- Second Method:
update housing_portfolio h_p
set h_p.SoldAsVacant = 
(
    case
        when lower(h_p.SoldAsVacant) = 'y' then 'Yes'
        when lower(h_p.SoldAsVacant) = 'n' then 'No'
        else h_p.SoldAsVacant
    end
);

--------------------------------------------------------------------------------
-- Remove duplicates
select * from housing_portfolio;

-- Visualizing duplicate values 1st method:
select * from 
(
select
    housing_portfolio.*,
    row_number() over(partition by parcelID, saleprice, propertyAddress, saledate, legalreference order by parcelID) as row_num
from housing_portfolio
) subquery
where subquery.row_num = 2;

-- Visualizing duplicate values 2th method:
with RowNumCTE as
    (
    select
        housing_portfolio.*,
        row_number() over(partition by parcelID, saleprice, propertyAddress, saledate, legalreference order by parcelID) as row_num
    from housing_portfolio
    )
select * from RowNumCTE
where row_num > 1;

-- Deleting duplicate values
select
    housing_portfolio.*      
from housing_portfolio
where (parcelID, saleprice, propertyAddress, saledate, legalreference) in (
    select parcelID, saleprice, propertyAddress, saledate, legalreference from 
    (
    select
        housing_portfolio.*,
        row_number() over(partition by parcelID, saleprice, propertyAddress, saledate, legalreference order by parcelID) as row_num
    from housing_portfolio
    ) subquery
    where subquery.row_num = 2
);

delete from housing_portfolio
where uniqueID in (
    select uniqueID
    from (
        select housing_portfolio.uniqueID,
            row_number() over(partition by parcelID, saleprice, propertyAddress, saledate, legalreference order by parcelID) as row_num
        from housing_portfolio
    ) subquery
    where subquery.row_num > 1
);

--------------------------------------------------------------------------------
-- Delete Unused Columns
select *
from housing_portfolio;
alter table housing_portfolio
drop (ownerAddress, acreage, taxDistrict, buildingValue);

