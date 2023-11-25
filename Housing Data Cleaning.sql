-----------------------------------------------------------------------------------------------------------------------
--Data Cleaning Steps
--Step 1: Standardize SaleDate to date format which was in varchar format before.
--Step 2: Handle missing value of Property Address by populating it using the ParcelID which identifies the same house.
--Step 3: Split the address column into individual address, State, City columns.
--Step 4: Converting binary column "SoldAsVacant" from 'y', 'n' to 'Yes' and 'No'
--Step 5: Remove duplicate data to avoid skewness.
--Step 6: Delete unused columns.
-----------------------------------------------------------------------------------------------------------------------

--Check for sample data
SELECT
    *
FROM PortfolioProject.dbo.NashvilleHousing
limit 100;


-- Standardize Date Format
SELECT
    saleDateConverted,
    CAST(SaleDate AS DATE)
FROM PortfolioProject.dbo.NashvilleHousing;


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CAST(SaleDate AS DATE);


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted DATE;


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CAST(SaleDate AS DATE);


-- Populate Property Address data
SELECT
    *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID;

UPDATE a
SET PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
    JOIN PortfolioProject.dbo.NashvilleHousing b ON a.ParcelID = b.ParcelID AND
                                                    a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


-- Breaking out Address into Individual Columns (Address, City, State)
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));



-- Split Owner Address
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-- Change Y and N to Yes and No in "Sold as Vacant" field
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                       WHEN SoldAsVacant = 'N' THEN 'No'
                       ELSE SoldAsVacant
                  END;


-- Remove Duplicates
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT
    *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress
;


-- Delete Unused Columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

