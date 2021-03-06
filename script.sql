USE [master]
GO
/****** Object:  Database [ICHIMS]    Script Date: 02/Feb/2020 11:32:18 PM ******/
CREATE DATABASE [ICHIMS]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'ICHIMS', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\ICHIMS.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'ICHIMS_log', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\ICHIMS_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [ICHIMS] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [ICHIMS].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [ICHIMS] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [ICHIMS] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [ICHIMS] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [ICHIMS] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [ICHIMS] SET ARITHABORT OFF 
GO
ALTER DATABASE [ICHIMS] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [ICHIMS] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [ICHIMS] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [ICHIMS] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [ICHIMS] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [ICHIMS] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [ICHIMS] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [ICHIMS] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [ICHIMS] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [ICHIMS] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [ICHIMS] SET  DISABLE_BROKER 
GO
ALTER DATABASE [ICHIMS] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [ICHIMS] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [ICHIMS] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [ICHIMS] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [ICHIMS] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [ICHIMS] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [ICHIMS] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [ICHIMS] SET RECOVERY FULL 
GO
ALTER DATABASE [ICHIMS] SET  MULTI_USER 
GO
ALTER DATABASE [ICHIMS] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [ICHIMS] SET DB_CHAINING OFF 
GO
ALTER DATABASE [ICHIMS] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [ICHIMS] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [ICHIMS]
GO
/****** Object:  StoredProcedure [dbo].[dbo.Sp_SCPRptDetailItemDiscountByManufacturer]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dbo.Sp_SCPRptDetailItemDiscountByManufacturer]
@paramItemTypeId INT,
@paramFromDate NVARCHAR(50),
@paramToDate NVARCHAR(50) 
AS
BEGIN 
SELECT ManufacturerName AS Manufacture_Name,TTL_ITM AS TotalItem,TotalAmount AS TotalPurchase,Discount_ITM AS NumberOfDiscountItem,
 Discount_VAL AS DiscountValue,
 CONVERT(varchar,ISNULL((Discount_VAL*100)/TotalAmount,0)) AS PercentageOfDiscountValue FROM 
  (
  SELECT SCPStManufactutrer.ManufacturerName,COUNT(SCPTnGoodReceiptNote_D.ItemCode) AS TTL_ITM,SUM(SCPTnGoodReceiptNote_D.NetAmount) AS TotalAmount,
  (SELECT COUNT(PRCD.ItemCode) FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.GoodReceiptNoteDetailId = PRCM.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PRCD.ItemCode
   WHERE PRCD.DiscountValue !=0 
  AND ITM.ManufacturerId=SCPStItem_M.ManufacturerId 
  AND cast(PRCM.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
  AND CAST(CONVERT(date,@paramToDate,103) as date)
  ) AS Discount_ITM ,
   (SELECT SUM(CASE WHEN DiscountType=1 THEN (DiscountValue) ELSE ((DiscountValue/100)*PRCD.TotalAmount) END)  FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.GoodReceiptNoteDetailId = PRCM.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PRCD.ItemCode
   WHERE PRCD.DiscountValue !=0 
  AND ITM.ManufacturerId=SCPStItem_M.ManufacturerId 
  AND cast(PRCM.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
  AND CAST(CONVERT(date,@paramToDate,103) as date)
  ) AS Discount_VAL 
  FROM SCPTnGoodReceiptNote_D
  INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnGoodReceiptNote_D.ItemCode
  INNER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId
  WHERE
   cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date)
    BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
	AND CAST(CONVERT(date,@paramToDate,103) as date)
	AND SCPStItem_M.ItemTypeId = @paramItemTypeId
  GROUP BY SCPStItem_M.ManufacturerId,SCPStManufactutrer.ManufacturerName
  )TMP
--WITH CTE_manufacturerDiscount(ManufactureName, 
--							  TotalItem,
--							  TotalPurchase,
--							  DiscountValue,
--							  NumberOfNotDiscountItem,
--							  NumberOfDiscountItem
--							  )
--AS
--(
--	SELECT  Manufacture.ManufacturerName AS ManufactureName,
--			SUM(ItemPurchaseD.RecievedQty) AS TotalItem,
--			SUM(ItemPurchaseD.NetAmount) AS TotalPurchase,
--			SUM(ItemPurchaseD.TotalAmount - ItemPurchaseD.AfterDiscountAmount) DiscountValue ,
--			SUM(CASE WHEN ItemPurchaseD.DiscountValue =0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfNotDiscountItem,
--			SUM(CASE WHEN ItemPurchaseD.DiscountValue !=0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfDiscountItem
--	FROM [dbo].[SCPStManufactutrerCategory] AS Manufacture
--	INNER JOIN [dbo].[SCPStItem_M] AS ItemManufacture ON Manufacture.ManufacturerId = ItemManufacture.ManufacturerId 
--	INNER JOIN [dbo].[SCPTnPharmacyIssuance_D] AS ItemPurchaseD ON ItemManufacture.ItemCode = ItemPurchaseD.ItemCode
--	WHERE  cast(ItemManufacture.CreatedDate as date) BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
--			AND CAST(CONVERT(date,@paramToDate,103) as date) AND
--		  ItemManufacture.ItemTypeId = @paramItemTypeId

--	GROUP BY Manufacture.ManufacturerName
--)

--SELECT ManufactureName, 
--	   ISNULL(TotalItem,0) AS TotalItem,
--	   ISNULL(TotalPurchase,0) AS TotalPurchase,
--	   ISNULL(DiscountValue,0) AS DiscountValue,
--	   ISNULL(NumberOfDiscountItem,0) AS NumberOfDiscountItem,
--	   ISNULL(NumberOfNotDiscountItem, 0) AS NumberOfNotDiscountItem,
--	   CONVERT(VARCHAR,ISNULL((Cast(DiscountValue as float)/TotalPurchase)*100 ,0))	 AS PercentageOfDiscountValue
--FROM CTE_manufacturerDiscount

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustmentForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPAdjustmentForSearch]
@SearchID as varchar(50)
AS
BEGIN
	SELECT SCPTnAdjustment_M.TRNSCTN_ID, SCPTnAdjustment_M.TRNSCTN_DATE, SCPStWraehouseName.WraehouseName
FROM SCPTnAdjustment_M INNER JOIN SCPStWraehouseName ON SCPTnAdjustment_M.WraehouseId = SCPStWraehouseName.WraehouseId
where SCPTnAdjustment_M.TRNSCTN_ID like '%'+@SearchID+'%'
ORDER BY SCPTnAdjustment_M.TRNSCTN_ID DESC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCheckItemExist]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPCheckItemExist]
@ItemCode as Varchar(50),
@ItemName as Varchar(50),
@GncId as INT,
@FrmlryID as INT,
@DsgFrmId as INT,
@StrengthIdId as INT,
@UnitId as INT

AS
BEGIN

	 if exists(select * from SCPStItem_M where ItemName=@ItemName and GenericId=@GncId and FormularyId=@FrmlryID 
	 and DosageFormId=@DsgFrmId and StrengthId=@StrengthIdId and ItemUnit=@UnitId and ItemCode!=@ItemCode)
	 begin 
	  select cast(1 as bit) as ExistCheck
	 end
	 else
	  begin 
	  select cast(0 as bit) as ExistCheck
	 end

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCheckItemGenericFormulary]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[Sp_SCPCheckItemGenericFormulary] 
@Exist as bit,
@GenericId as bigint,
@FORMU_ID as bigint
AS
BEGIN
	IF EXISTS (SELECT a.GenericId,a.FormularyId FROM SCPStItem_M a WHERE a.GenericId=@GenericId AND a.FormularyId=@FORMU_ID)
set @Exist=1 else set @Exist=0
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_S]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPCRP014_S]
@Trnsctn_ID as varchar(50)

AS
BEGIN
	SELECT CA.TRNSCTN_ID, CA.TRNSCTN_DATE, CA.FromDate, CA.ToDate, SCPStWraehouseName.WraehouseName
FROM   SCPStParLevelAssignment_M CA INNER JOIN SCPStWraehouseName ON CA.WraehouseId = SCPStWraehouseName.WraehouseId where CA.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%'
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGenerateAlertNo]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateAlertNo]
AS
BEGIN
	SELECT 'AL-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(CreatedDate)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnAlert_M
	WHERE MONTH(CreatedDate) = MONTH(getdate())
    AND YEAR(CreatedDate) = YEAR(getdate())
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGenerateBatchNo]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateBatchNo]

AS
BEGIN
	SELECT 'BN-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(BatchNo)+1 AS VARCHAR(50)),4) AS BatchNo
    FROM SCPTnBatchNo_M
	WHERE MONTH(BatchNoStartTime) = MONTH(getdate())
    AND YEAR(BatchNoStartTime) = YEAR(getdate())

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGenerateItemCode]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateItemCode]
AS
BEGIN
	SELECT CAST(((SELECT TOP 1 ItemCode FROM SCPStItem_M ORDER BY ItemCode DESC)+1) AS varchar(50)) AS ItemCode
	--SELECT '9'+RIGHT('0000000'+CAST(COUNT(ItemCode)+1 AS VARCHAR(7)),7) AS ItemCode
 --   FROM SCPStItem_M 
END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGeneratekitNo]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[Sp_SCPGeneratekitNo]

AS
BEGIN
	SELECT 'KI-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(KitId)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPStKit_M

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGeneratePurchaseOrderDiscardNo]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGeneratePurchaseOrderDiscardNo]
AS
BEGIN
	SELECT 'PD-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRANSCTN_ID
    FROM SCPTnPODiscard_M 
	WHERE MONTH(TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(TRANSCTN_DT) = YEAR(getdate())
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGeneratePurchaseRequisitionDiscardNo]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGeneratePurchaseRequisitionDiscardNo]
AS
BEGIN
	SELECT 'PD-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRANSCTN_ID
    FROM SCPTnPRDiscard_M 
	WHERE MONTH(TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(TRANSCTN_DT) = YEAR(getdate())
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGenerateReturnToSupplierNo]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGenerateReturnToSupplierNo]

AS
BEGIN
	SELECT 'RS-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(ReturnToSupplierId)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnReturnToSupplier_M

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGenericBySbCategoryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGenericBySbCategoryForSearch]
 

 @Search as varchar(50),
 @SubCateId as int

AS
BEGIN

 SET NOCOUNT ON;

select a.GenericName,a.GenericId,a.IsActive, a.SubCategoryId  from SCPStGeneric as a
where a.GenericName LIKE '%'+@Search+'%'and a.SubCategoryId= @SubCateId order by a.GenericId desc

END






GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetAdmitPatientForRefund]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAdmitPatientForRefund]
AS
BEGIN
	 SELECT distinct SCPTnSale_M.PatientIp as PatientIp, SCPTnSale_M.PatientIp as PatientIpNO  FROM  SCPTnInPatient 
	 INNER JOIN SCPTnSale_M ON SCPTnInPatient.PatientIp = SCPTnSale_M.PatientIp WHERE SCPTnInPatient.Status=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetAllItemDetails]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAllItemDetails]
AS
BEGIN
	SELECT SCPStItem_M.ItemCode,ItemName,Pneumonics,ClassName,SubClassName,CategoryName,SubCategoryName,GenericName,DosageName,
	CASE WHEN FormularyName IS NULL THEN 'NON-FORMULARY' ELSE FormularyName END AS FormularyName,
	UnitName,SignaName,STG.StrengthIdName,RouteOfAdministrationTitle,CurrentStock FROM SCPStItem_M
	INNER JOIN SCPStClassification CLS ON SCPStItem_M.ClassId = CLS.ClassId
	INNER JOIN SCPStSubClassification SBCLS ON SCPStItem_M.SubClassId = SBCLS.SubClassId 
	INNER JOIN SCPStCategory CAT ON CAT.CategoryId = SCPStItem_M.CategoryId
	INNER JOIN SCPStSubCategory SBCAT ON SCPStItem_M.SubCategoryId = SBCAT.SubCategoryId 
	INNER JOIN SCPStGeneric GEN ON SCPStItem_M.GenericId = GEN.GenericId
	INNER JOIN SCPStDosage DOS ON DOS.DosageId = SCPStItem_M.DosageFormId
	LEFT OUTER JOIN SCPStFormulary FRM ON FRM.FormularyId = SCPStItem_M.FormularyId
	INNER JOIN SCPStMeasuringUnit UNIT ON UnitId = SCPStItem_M.ItemUnit
	INNER JOIN SCPStSigna SIG ON SIG.SignaId = SCPStItem_M.SignaId
	INNER JOIN SCPStStrengthId STG ON STG.StrengthIdId = SCPStItem_M.StrengthId
	INNER JOIN SCPStRouteOfAdministration ROA ON ROA.RouteOfAdministrationId = SCPStItem_M.RouteOfAdministrationId 
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=3
	ORDER BY ItemName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetApprovalMatrixLevel]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetApprovalMatrixLevel]
@DocType as varchar(50),
@ItemClassfctn as int,
@POAmount as money
AS
BEGIN
	
	--select Designation,Limit,coalesce(LEAD(Limit) over (order by ApprovalLevelId), 10000000000) as Limit_TO
	 --from SCPStApproval where ClassificationId=@ItemClassfctn and DocumentType=@DocType

	 select Designation,coalesce(Lag(Limit) over (order by ApprovalLevelId), 0) as Limit_FRM,Limit
     from SCPStApproval where DocumentType=@DocType and ClassificationId=@ItemClassfctn AND Limit<=(select Top 1 Limit 
     from SCPStApproval where DocumentType=@DocType and ClassificationId=@ItemClassfctn and Limit>=@POAmount) and IsActive=1;

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetAutoParLevel]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetAutoParLevel]
@WAREOUSE_ID AS INT
AS BEGIN
SELECT WraehouseName,ParLevelName,ParLevelDays,ParLevelApplyDays,ParLevelConsumptionDays FROM SCPStAutoParLevel_M APL
INNER JOIN SCPStWraehouseName WH ON APL.WraehouseId = WH.WraehouseId
INNER JOIN SCPStParLevel LVL ON LVL.ParLevelId = APL.ParLevelId
WHERE APL.WraehouseId=@WAREOUSE_ID
END 




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetAutoParLevelByWraehouseName]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetAutoParLevelByWraehouseName]
@WraehouseId AS INT
AS BEGIN
SELECT ParLevelId,ParLevelDays,ParLevelApplyDays,ParLevelConsumptionDays FROM SCPStAutoParLevel_M
WHERE WraehouseId=@WraehouseId AND IsActive=1
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetAutoParLevelItems]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetAutoParLevelItems]
@AVG_DAYS AS INT,
@WARWHOUSE_ID AS INT,
@ParLevelDays AS MONEY

AS BEGIN


IF(@WARWHOUSE_ID=3)
	BEGIN

		SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN NEW_PAR_LVL<= 0 THEN 1 ELSE NEW_PAR_LVL END AS ITM_PAR_LVL FROM 
		(
			SELECT CC.ItemCode,ItemPackingQuantity,CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT) AVG_CNSMPTN,
				CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0)*@ParLevelDays AS INT) AS NEW_PAR_LVL
				FROM SCPStItem_M CC
				LEFT OUTER JOIN SCPTnSale_D PHD ON PHD.ItemCode = CC.ItemCode 
				AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE()
				WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
				 AND ISNULL(MedicalNeedItem,0)!=1 AND ISNULL(OnHold,0)!=1 AND ISNULL(FreezItem,0)!=1 AND FormularyId!=0
				GROUP BY CC.ItemCode,ItemPackingQuantity,CC.CreatedDate
		)TMPP ORDER BY ItemCode
		END

ELSE IF(@WARWHOUSE_ID=10)
	BEGIN

	SELECT ItemCode,ItemPackingQuantity,CAST(ROUND(AVG_CNSMPTN,0) AS INT) AVG_CNSMPTN,
	CASE WHEN ITM_PAR_LVL >0 AND ITM_PAR_LVL < @ParLevelDays THEN CAST(ROUND(@ParLevelDays,0) AS INT) ELSE CAST(ROUND(ITM_PAR_LVL,0) AS INT) END AS ITM_PAR_LVL FROM 
	(
		SELECT CC.ItemCode,ItemPackingQuantity,(CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)) AVG_CNSMPTN,
			(CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT))*@ParLevelDays*TotalSupplyDays AS ITM_PAR_LVL
			FROM SCPStItem_M CC
			LEFT OUTER JOIN SCPTnSale_D PHD ON PHD.ItemCode = CC.ItemCode 
			AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE()
			INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = CC.ItemCode 
			INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
			INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
			WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
			 AND ISNULL(MedicalNeedItem,0)!=1 AND ISNULL(OnHold,0)!=1 AND ISNULL(FreezItem,0)!=1 AND FormularyId!=0
			GROUP BY CC.ItemCode,ItemPackingQuantity,TotalSupplyDays --ORDER BY CC.ItemCode
		)TMPP ORDER BY ItemCode

	END


--IF(@WARWHOUSE_ID=3)
--	BEGIN

--		SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN ITM_PAR_LVL<= 0 THEN 1 ELSE ITM_PAR_LVL END AS ITM_PAR_LVL FROM 
--		(
--			SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN @IS_PACK_APPLY=1 THEN 
--			CASE WHEN NEW_PAR_LVL=0 THEN 0 WHEN NEW_PAR_LVL<ItemPackingQuantity THEN ItemPackingQuantity 
--			ELSE CAST(((ROUND(CAST(NEW_PAR_LVL AS decimal)/CAST(ItemPackingQuantity  AS decimal),0))*ItemPackingQuantity) as int) END 
--			ELSE NEW_PAR_LVL END AS ITM_PAR_LVL FROM
--			(
--				SELECT CC.ItemCode,ItemPackingQuantity,CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT) AVG_CNSMPTN,
--				CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT)*@ParLevelDays AS NEW_PAR_LVL
--				FROM SCPStItem_M CC
--				LEFT OUTER JOIN SCPTnSale_D PHD ON PHD.ItemCode = CC.ItemCode 
--				AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE()
--				WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
--				AND CC.MedicalNeedItem=0 AND OnHold!=1 AND FreezItem!=1
--				GROUP BY CC.ItemCode,ItemPackingQuantity,CC.CreatedDate
--			)TMP 
--		)TMPP ORDER BY ItemCode
--		END

--ELSE IF(@WARWHOUSE_ID=10)
--	BEGIN

--		SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN @IS_PACK_APPLY=1 THEN 
--		CASE WHEN NEW_PAR_LVL=0 THEN 0  WHEN NEW_PAR_LVL<ItemPackingQuantity THEN ItemPackingQuantity 
--		ELSE CAST(((ROUND(CAST(NEW_PAR_LVL AS decimal)/CAST(ItemPackingQuantity  AS decimal),0))*ItemPackingQuantity) as int) END 
--		ELSE NEW_PAR_LVL END AS ITM_PAR_LVL FROM
--		(
--			SELECT CC.ItemCode,ItemPackingQuantity,CAST(ROUND((CAST(ISNULL(SUM(PHD.IssueQty),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT) AVG_CNSMPTN,
--			CAST(ROUND((CAST(ISNULL(SUM(PHD.IssueQty),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT)*@ParLevelDays*TotalSupplyDays AS NEW_PAR_LVL
--			FROM SCPStItem_M CC
--			LEFT OUTER JOIN SCPTnPharmacyIssuance_D PHD ON PHD.ItemCode = CC.ItemCode 
--			AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE() 
--			INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = CC.ItemCode 
--			INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
--			INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
--			WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
--			AND CC.MedicalNeedItem=0 AND OnHold!=1 AND FreezItem!=1
--			GROUP BY CC.ItemCode,ItemPackingQuantity,TotalSupplyDays
--		)TMP ORDER BY ItemCode

--	END
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetBatchNoOpenCloseBalance]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoOpenCloseBalance]
@BatchNo as varchar(50),
@UsrId as int 
AS
BEGIN

	SET NOCOUNT ON;
    	SELECT (SELECT TOP (1) OpeningClose FROM SCPTnBatchNo_D WHERE USR_ID =@UsrId
	 AND BatchNo = @BatchNo order by ID DESC ) AS OPENING_BAL,(SELECT ISNULL(sum(SCPTnSale_D.Amount),0) as TotalSale FROM SCPTnSale_D 
    INNER JOIN SCPTnSale_M ON SCPTnSale_D.PARNT_TRANS_ID = SCPTnSale_M.TRANS_ID 
    where SCPTnSale_M.BatchNo= @BatchNo and SCPTnSale_M.CRTD_BY = @UsrId) AS SALE
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetBatchNoUserId]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoUserId]
@BatchNo as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

  select CRTD_BY from SCPTnBatchNo_M where BatchNo = @BatchNo
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetBatchNoUserName]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoUserName]
@BatchNo as varchar(50),
@UsrId as int 
AS
BEGIN
	
	SET NOCOUNT ON;
	SELECT UserName FROM SCPTnBatchNo_M INNER JOIN SCPStUser_M ON SCPStUser_M.USR_ID = SCPTnBatchNo_M.CRTD_BY 
	--INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.USR_ID = SCPTnBatchNo_D.USR_ID
 WHERE SCPTnBatchNo_M.BatchNo = @BatchNo AND SCPTnBatchNo_M.CRTD_BY != @UsrId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Sp_SCPGetCategory]
 
  @ID AS bigint
 

AS
BEGIN

 SET NOCOUNT ON;

select a.CategoryId,a.CategoryName,a.IsActive,b.SubClassName,a.SubClassId  from SCPStCategory as a 
inner join SCPStSubClassification as b on a.SubClassId=a.SubClassId

where b.SubClassId=@ID

END










GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCategoryBySbClass]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryBySbClass]
 
  @ID AS bigint
 

AS
BEGIN

 SET NOCOUNT ON;

select a.CategoryId,a.CategoryName,a.IsActive,b.SubClassName,a.SubClassId  from SCPStCategory as a 
inner join SCPStSubClassification as b on a.SubClassId=b.SubClassId

where b.SubClassId=@ID

ORDER BY A.CategoryId Desc
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCategoryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryForSearch]
	@SubClassId as int,
	@Cat_NAME as varchar(50)
AS
BEGIN

     SELECT  C.CategoryId, C.CategoryName, b.SubClassName,b.SubClassId ,C.IsActive
     FROM  SCPStCategory C INNER JOIN SCPStSubClassification as b ON  C.SubClassId = b.SubClassId
	 WHERE C.SubClassId=@SubClassId 
	 --and C.CategoryName LIKE '%'+@Cat_NAME+'%'
	 ORDER BY CategoryId DESC
	 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCategoryList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryList]
AS
BEGIN
	select a.CategoryId,a.CategoryName from SCPStCategory as a
     where IsActive=1  order by CategoryName 
 END






GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCategoryListByItemType]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryListByItemType]
	@ItemTypeId as int	
AS
BEGIN
	
	SELECT  CAT.CategoryId, CategoryName  FROM SCPStClassification CLS
	 INNER JOIN SCPStSubClassification SB_CLS ON CLS.ClassId = SB_CLS.ClassId
	INNER JOIN SCPStCategory CAT  ON SB_CLS.SubClassId = CAT.SubClassId WHERE CLS.ItemTypeId = @ItemTypeId
	order by CategoryName
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCategoryListBySbClass]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryListBySbClass]
@SbClassId as int
AS
BEGIN
	select a.CategoryId,a.CategoryName from SCPStCategory as a
     where IsActive=1 and SubClassId=@SbClassId order by a.CategoryName
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCity]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCity]
@CityId as int
AS
BEGIN
     SELECT CityName,CountryId,IsActive
     FROM SCPStCity  WHERE CityId=@CityId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCityForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCityForSearch]
	@CategoryId  as int,
	@name as varchar(50)
AS
BEGIN
SELECT C.CityId,C.CityName,C.IsActive,CS.CountryName
FROM  SCPStCity C,SCPStCountry CS
WHERE C.CityName LIKE '%'+@name+ '%' and c.CountryId=@CategoryId  AND C.CountryId=CS.CountryId
ORDER BY C.CityName
	 --SELECT C.CityId, C.CityName, SCPStCountry.CountryName, SCPStCountry.IsActive
  --   FROM SCPStCity C INNER JOIN SCPStCountry ON C.CountryId = SCPStCountry.CountryId WHERE C.CountryId=@CNTRY_ID and C.CityName LIKE '%'+@CityName+'%' 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetClassByItemTypeForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetClassByItemTypeForSearch]
 
   @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.ClassId,a.ClassName,a.IsActive,b.ItemTypeId,b.ItemTypeName  from SCPStClassification as a inner join SCPStItemType as b on a.ItemTypeId=b.ItemTypeId
where b.ItemTypeId=@ID and a.ClassName LIKE '%'+@Search+'%'
ORDER BY A.ClassId Desc

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetClassForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPGetClassForSearch]
 
   @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.ClassId,a.ClassName,a.IsActive,b.ItemTypeId,b.ItemTypeName  from SCPStClassification as a 
inner join SCPStItemType as b on a.ItemTypeId=b.ItemTypeId
where a.ClassId=@ID and a.ClassName LIKE '%'+@Search+'%' 

END








GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetClassList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetClassList]
AS
BEGIN
	select a.ClassId,a.ClassName from SCPStClassification as a
     where IsActive=1 order by a.ClassName
 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetClassListByItemType]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetClassListByItemType]
@ItemTypeId as int
AS
BEGIN
	select a.ClassId,a.ClassName from SCPStClassification as a
     where IsActive=1 and ItemTypeId=@ItemTypeId order by a.ClassName
 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetClassSbClassByItemType]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetClassSbClassByItemType] 
@ItemTypeId as int	
AS
BEGIN

SELECT SB_CLS.SubClassId,SB_CLS.SubClassName FROM SCPStClassification  CLS 
INNER JOIN SCPStSubClassification SB_CLS ON CLS.ClassId = SB_CLS.ClassId
WHERE CLS.ItemTypeId = @ItemTypeId AND SB_CLS.IsActive = 1 order by SB_CLS.SubClassName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCompany]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetCompany]
(
@CompanyId AS INT)
AS
BEGIN
SELECT C.IsActive,c.CompanyCode,c.CompanyPRF,C.CompanyName
FROM SCPStCompany C
WHERE C.CompanyId=@CompanyId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCompanyForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetCompanyForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.CompanyId,C.CompanyName,c.CompanyCode,c.CompanyPRF,C.IsActive
FROM  SCPStCompany C
WHERE C.CompanyName LIKE '%'+@name+ '%' 
ORDER BY C.CompanyId Desc
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCompanyList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCompanyList]

AS
BEGIN
	 select CompanyId,CompanyName from SCPStCompany where IsActive=1 order by CompanyName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetConsultant]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetConsultant]
@ConsultantId as int
AS
BEGIN
     SELECT ConsultantName,QualificationId,SpecialityId,IsActive 
     FROM SCPStConsultant  WHERE ConsultantId=@ConsultantId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetConsultantForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetConsultantForSearch]
	@SpecialityId as int,
	@QualificationId as int,
	@ConsultantName as varchar(50)
AS
BEGIN
	 SELECT  C.ConsultantId, C.ConsultantName, SCPStQualification.QualificationName, SCPStSpeciality.ConsultantSpecialityName,
     C.IsActive FROM  SCPStConsultant C INNER JOIN SCPStSpeciality ON C.SpecialityId = SCPStSpeciality.ConsultantSpecialityId 
     INNER JOIN SCPStQualification ON C.QualificationId = SCPStQualification.QualificationId WHERE C.SpecialityId=@SpecialityId 
     AND C.QualificationId=@QualificationId AND C.ConsultantName LIKE '%'+@ConsultantName+'%' 
	 ORDER BY C.ConsultantName

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetConsultantList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetConsultantList]
AS
BEGIN
SELECT C.HIMSConsultantId AS  ConsultantId,C.ConsultantName
FROM SCPStConsultant C WHERE IsActive=1 order by C.ConsultantName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCountry]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetCountry]
(
@COUNTRY_ID AS INT)
AS
BEGIN
SELECT C.CountryName,C.IsActive
FROM SCPStCountry C
WHERE C.CountryId=@COUNTRY_ID
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCountryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetCountryForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.CountryId,C.CountryName,C.IsActive
FROM  SCPStCountry C
WHERE C.CountryName LIKE '%'+@name+ '%' 
ORDER BY C.CountryName
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetCountryList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCountryList]
AS
BEGIN
	select CountryId,CountryName from SCPStCountry
     where IsActive=1 order by CountryName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDemandForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandForSearch] 
@Search as varchar(50),
@DmndType as varchar(1)
AS
BEGIN
	SELECT SCPTnDemand_M.TRNSCTN_ID, SCPTnDemand_M.TRNSCTN_DATE, SCPStWraehouseName.WraehouseName
	FROM  SCPTnDemand_M INNER JOIN SCPStWraehouseName ON SCPTnDemand_M.WraehouseId = SCPStWraehouseName.WraehouseId
	where SCPTnDemand_M.DemandType=@DmndType and 
	SCPTnDemand_M.TRNSCTN_ID like '%'+@Search+'%' 
	ORDER BY SCPTnDemand_M.TRNSCTN_ID desc
	
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDepartment]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[Sp_SCPGetDepartment]
(
@DepartmentId AS INT)
AS
BEGIN
SELECT C.DepartmentName,C.IsActive
FROM SCPStDepartment C
WHERE C.DepartmentId=@DepartmentId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDepartmentForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetDepartmentForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT DepartmentName ,DepartmentId,IsActive
FROM  SCPStDepartment
WHERE DepartmentName LIKE '%'+@name+ '%' 
ORDER BY DepartmentId Desc
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDepartmentList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDepartmentList]
AS
BEGIN
	select DepartmentId as DPTMNT_ID ,DepartmentName  as DPTMNT from SCPStDepartment where IsActive=1 order by DepartmentName
 END 



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDesignationAndLimit]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDesignationAndLimit]
@DocType as varchar(50),
@ItemClassfctn as int
AS
BEGIN
	select Designation,Limit from SCPStApproval where ClassificationId=@ItemClassfctn and DocumentType=@DocType and IsActive=1
	
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDosageForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDosageForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.DosageId,a.DosageName,a.IsActive  from SCPStDosage as a
where a.DosageName LIKE '%'+@Search+'%' 
ORDER BY A.DosageId DESC 

END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDosageList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDosageList]

AS
BEGIN
	 select DosageId,DosageName from SCPStDosage where IsActive=1 order by DosageName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDose]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDose]
@DoseId as int
AS
BEGIN
      select DoseName,IsActive from SCPStDose where DoseId=@DoseId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetDoseForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDoseForSearch]
	
	@DoseName as varchar(50)
AS
BEGIN
	 SELECT DoseId,DoseName,IsActive
     FROM SCPStDose C WHERE DoseName LIKE '%'+@DoseName+'%' 
	 ORDER BY DoseId DESC 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetEmployee]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployee]
@EmpId as varchar(50)
AS
BEGIN
	 select EmployeeCode as EMP_ID,EmployeeName as EMP_NM from SCPStEmployee where IsActive=1 and EmployeeCode=@EmpId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetEmployeeforSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeforSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

--select a.EMP_NM,a.EMP_ID,a.IsActive  from SCPStEmployee as a
--where a.EMP_NM LIKE '%'+@Search+'%' 
select a.EmployeeName,a.EmployeeCode,a.IsActive  from SCPStEmployee as a
where a.EmployeeName LIKE '%'+@Search+'%' 
ORDER BY EmployeeCode Desc
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetEmployeeGroup]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeGroup]
@GroupId as int
AS
BEGIN
      select EmployeeGroup,IsActive from SCPStEmployeeGroup where EmployeeGroupId=@GroupId
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetEmployeeGroupForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeGroupForSearch]
	
	@GroupName as varchar(50)
AS
BEGIN
	 SELECT EmployeeGroupId,EmployeeGroup,IsActive
     FROM SCPStEmployeeGroup WHERE EmployeeGroup LIKE '%'+@GroupName+'%' 
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetEmployeeGroupList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeGroupList]
AS
BEGIN
	 select EmployeeGroupId,EmployeeGroup from SCPStEmployeeGroup where IsActive=1 order by EmployeeGroup
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetExpiredItems]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiredItems]
AS
BEGIN
	SELECT ItemName,BatchNo,CurrentStock,CONVERT(VARCHAR(10), ISSUE_DATE, 105) AS ISSUE_DATE,
	CONVERT(VARCHAR(10),EXP_DATE, 105) AS EXP_DATE FROM
	(
		SELECT SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock,
		MAX(SCPTnStock_M.CreatedDate) AS ISSUE_DATE,MAX(SCPTnGoodReceiptNote_D.ExpiryDate) EXP_DATE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPStItem_M.ItemCode=SCPTnStock_M.ItemCode AND SCPTnStock_M.WraehouseId=3
		INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
		AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
		GROUP BY SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock
	)
 TMP WHERE CurrentStock>0 AND EXP_DATE<GETDATE()

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetExpiredItemsPercentage]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiredItemsPercentage]
AS
BEGIN

WITH CTE AS
(
 SELECT COUNT(ItemCode) AS EXPRY_ITM,(SELECT COUNT(ItemCode) FROM
 (
   SELECT SCPTnStock_M.ItemCode,SUM(CurrentStock) AS CurrentStock,MAX(ExpiryDate) AS EXP_DATE FROM SCPTnStock_M 
   INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
   AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
   AND SCPTnStock_M.WraehouseId=3  GROUP BY SCPTnStock_M.ItemCode
 )TMP WHERE CurrentStock>0) AS TTL_ITM FROM
  (
   SELECT DISTINCT ItemCode FROM
   (
    SELECT SCPTnStock_M.ItemCode,SCPTnStock_M.BatchNo,CurrentStock,
	max(SCPTnGoodReceiptNote_D.ExpiryDate) AS EXP_DATE FROM SCPTnStock_M
    INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
	AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
    AND SCPTnStock_M.WraehouseId=3 GROUP BY SCPTnStock_M.ItemCode,CurrentStock,SCPTnStock_M.BatchNo
	 )TMP WHERE CurrentStock>0 AND EXP_DATE<GETDATE()
  )TT
)SELECT (EXPRY_ITM*100)/TTL_ITM AS EXPRD_ITM FROM CTE

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetExpiryCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryCategory]
@ExpiryCatId as int
AS
BEGIN
      select ExpiryCategoryT,ExpiryDurationFrom,ExpiryDurationFromType,ExpiryDurationTo,ExpiryDurationToType,
	  IntimationTime,IntimationTimeType,OffShelfTime,OffShelfTimeType,IsActive 
	  from SCPStExpiryCategory where ExpiryCategoryId=@ExpiryCatId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetExpiryCategoryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryCategoryForSearch]
@ExpiryCat as varchar(50)
AS
BEGIN
      SELECT ExpiryCategoryId,ExpiryCategoryT,ExpiryDurationFrom,(SELECT TimeDurationType FROM SCPStTimeType 
	  WHERE TimeDurationTypeId=ExpiryDurationFromType) AS ExpiryDurationFromType,ExpiryDurationTo,
	  (SELECT TimeDurationType FROM SCPStTimeType WHERE TimeDurationTypeId=ExpiryDurationToType) AS ExpiryDurationToType,
	  IntimationTime,(SELECT TimeDurationType FROM SCPStTimeType 
	  WHERE TimeDurationTypeId=IntimationTimeType) AS IntimationTimeType,
	  OffShelfTime,(SELECT TimeDurationType FROM SCPStTimeType 
	  WHERE TimeDurationTypeId=OffShelfTimeType) AS OffShelfTimeType,SCPStExpiryCategory.IsActive FROM SCPStExpiryCategory 
	  WHERE ExpiryCategoryT LIKE '%'+@ExpiryCat+'%' 
	  ORDER BY ExpiryCategoryT desc
END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetExpiryItems]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryItems]
@WraehouseId AS INT
AS
BEGIN
	SELECT ClassName,ItemCode,ItemName,BatchNo,DosageName,CurrentStock,CONVERT(VARCHAR(10), ISSUE_DATE, 105) AS ISSUE_DATE,
	CONVERT(VARCHAR(10),EXP_DATE, 105) AS EXP_DATE FROM
   (
    SELECT CONVERT(VARCHAR(50),ClassName) as ClassName ,SCPStItem_M.ItemCode,SCPStItem_M.ItemName,DosageName,
	SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock,
    MAX(SCPTnStock_M.CreatedDate) AS ISSUE_DATE,MAX(SCPTnGoodReceiptNote_D.ExpiryDate) EXP_DATE FROM SCPStItem_M
    INNER JOIN SCPTnStock_M ON SCPStItem_M.ItemCode=SCPTnStock_M.ItemCode AND SCPTnStock_M.WraehouseId=@WraehouseId
    INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
	AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
	INNER JOIN SCPStClassification on SCPStClassification.ClassId = SCPStItem_M.ClassId
	INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
    GROUP BY ClassName,SCPStItem_M.ItemCode,SCPStItem_M.ItemName,DosageName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock
   )
   TMP WHERE CurrentStock>0 AND EXP_DATE BETWEEN CONVERT(DATE,GETDATE()) 
   AND DATEADD(month,6, CONVERT(DATE,GETDATE())) ORDER BY ItemName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetExpiryItemsPercentage]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryItemsPercentage]
AS
BEGIN
	WITH CTE AS
	(
	 SELECT COUNT(ItemCode) AS EXPRY_ITM,(SELECT COUNT(ItemCode) FROM
	 (
	   SELECT SCPTnStock_M.ItemCode,SUM(CurrentStock) AS CurrentStock,MAX(ExpiryDate) AS EXP_DATE FROM SCPTnStock_M 
	   INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
	   AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
	   AND SCPTnStock_M.WraehouseId=3  GROUP BY SCPTnStock_M.ItemCode
	 )TMP WHERE CurrentStock>0) AS TTL_ITM FROM
	  (
	   SELECT DISTINCT ItemCode FROM
	   (
		SELECT SCPTnStock_M.ItemCode,SCPTnStock_M.BatchNo,CurrentStock,max(SCPTnGoodReceiptNote_D.ExpiryDate) AS EXP_DATE FROM SCPTnStock_M
		INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
		AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
		AND SCPTnStock_M.WraehouseId=3 GROUP BY SCPTnStock_M.ItemCode,CurrentStock,SCPTnStock_M.BatchNo
		)TMP WHERE CurrentStock>0 AND EXP_DATE BETWEEN CONVERT(DATE,GETDATE()) AND DATEADD(month,6, CONVERT(DATE,GETDATE()))
	  )TT
)SELECT (EXPRY_ITM*100)/TTL_ITM AS EXPRD_ITM FROM CTE
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFeild]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetFeild]
(
@FIELD AS INT)
AS
BEGIN
SELECT C.CConsultantFeildName,C.IsActive
FROM SCPStFeild C
WHERE C.ConsultantFeildId=@FIELD
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFeildForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetFeildForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.ConsultantFeildId,C.CConsultantFeildName,C.IsActive
FROM  SCPStFeild C
WHERE C.CConsultantFeildName LIKE '%'+@name+ '%' 
ORDER BY C.ConsultantFeildId Desc
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFeildList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetFeildList]
AS
BEGIN
SELECT C.ConsultantFeildId,C.CConsultantFeildName
FROM SCPStFeild C where C.IsActive=1 order by C.CConsultantFeildName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFormulary]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetFormulary]
(
@FormCode AS INT)
AS
BEGIN
SELECT SCPStFormulary.FormularyName, SCPStFormulary.PriorityNo,IsActive
FROM SCPStFormulary 
WHERE SCPStFormulary.FormularyId=@FormCode
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFormularyBygeneric]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetFormularyBygeneric]
@FormularyType as int,
@GenericId as int
AS
BEGIN
	--select FormularyId,FormularyName from SCPStFormulary where IsActive=1 and FRMLRY_TYPE_ID=@FormularyType
	select FormularyId,FormularyName from SCPStFormulary where IsActive=1 
    and FormularyId NOT IN(select FormularyId from SCPStItem_M where GenericId=@GenericId)
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFormularyForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPGetFormularyForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT SCPStFormulary.FormularyId, SCPStFormulary.FormularyName, SCPStFormulary.PriorityNo, SCPStFormulary.IsActive
FROM SCPStFormulary 
WHERE FormularyName LIKE '%'+@name+ '%' 
order by SCPStFormulary.FormularyId DESC
END  



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetFormularyList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetFormularyList]
@FormularyType as int

AS
BEGIN
	select FormularyId,FormularyName from SCPStFormulary where IsActive=1 order by FormularyName

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetGenericBySbCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[Sp_SCPGetGenericBySbCategory]
 @SubCateId as int
AS
BEGIN
	SET NOCOUNT ON;
SELECT GenericId, GenericName, IsActive FROM SCPStGeneric WHERE SubCategoryId = @SubCateId order by GenericId Desc
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetGenericList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGenericList]

AS
BEGIN
	 select GenericId,GenericName from SCPStGeneric where IsActive=1 order by GenericName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetGoodRecieptNote_M]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodRecieptNote_M]
@Trnsctn_ID as varchar(50)

AS
BEGIN
	 SELECT TRNSCTN_ID, TRNSCTN_DATE, SCPTnGoodReceiptNote_M.SupplierId,SCPTnGoodReceiptNote_M.WraehouseId,IsApproved ,PurchaseOrderNo,SCPStWraehouseName.ItemTypeId, 
	 SupplierLongName,
	 ChallanNo, ChallanDate,InvoiceNo,InvoiceDate, TotalAmount,GRNType,TotalSaleTax,
	 GRNAmount,TotalDiscount, NetAmount FROM SCPTnGoodReceiptNote_M
	 INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId = SCPTnGoodReceiptNote_M.WraehouseId
	 INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = SCPTnGoodReceiptNote_M.SupplierId
	 where SCPTnGoodReceiptNote_M.IsActive=1 and TRNSCTN_ID=@Trnsctn_ID
END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetGoodRecieptNoteForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodRecieptNoteForSearch]
@Trnsctn_ID as varchar(50),
@ItemTypeID as int

AS
BEGIN

	SELECT PR.TRNSCTN_ID, PR.TRNSCTN_DATE, SCPStSupplier.SupplierLongName AS SupplierShortName,SCPStWraehouseName.WraehouseName, PR.PurchaseOrderNo, 
PR.ChallanNo, PR.ChallanDate FROM SCPTnGoodReceiptNote_M PR 
INNER JOIN SCPStSupplier ON PR.SupplierId = SCPStSupplier.SupplierId AND SCPStSupplier.ItemTypeId=@ItemTypeID
INNER JOIN SCPStWraehouseName ON PR.WraehouseId = SCPStWraehouseName.WraehouseId AND SCPStWraehouseName.ItemTypeId=@ItemTypeID
 where PR.IsActive=1 AND PR.TRNSCTN_ID like '%'+@Trnsctn_ID+'%'
 ORDER BY PR.TRNSCTN_ID DESC

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetGoodReturnForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodReturnForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,b.WraehouseName,b.WraehouseId, DepartmentId, DepartmentName
FROM  SCPTnGoodReturn_M as a 
inner join SCPStWraehouseName as b on b.WraehouseId=a.WarehouseId
INNER JOIN SCPStDepartment ON SCPStDepartment.DepartmentId = A.DepartmentId
 where a.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or  CAST(a.TRANSCTN_DT AS DATE) like '%'+@Trnsctn_ID+'%' 
 or b.WraehouseName like '%'+@Trnsctn_ID+'%'
 ORDER BY A.TRANSCTN_ID DESC
END














GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetInPatient]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetInPatient]
(

@patId varchar(50)
)
as
begin
select * from SCPTnInPatient
where  PatientIp=@patId
end


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetInPatientDetail]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>



-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetInPatientDetail]
@PatinetIp AS VARCHAR(50)
AS
BEGIN
	 SELECT DISTINCT NamePrefix+' '+FirstName+' '+LastName AS SCPTnInPatient_NM,SCPStPatientType.PatientTypeName,
	 isnull(SCPStCompany.CompanyName,'') as CompanyName FROM SCPTnSale_M 
	 INNER JOIN SCPStPatientType ON SCPTnSale_M.PatientTypeId = SCPStPatientType.PatientTypeId
	 LEFT OUTER JOIN SCPStCompany ON SCPTnSale_M.CompanyId=SCPStCompany.CompanyId
	 WHERE SCPTnSale_M.PatientIp= @PatinetIp
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetInventoryVsCOGS]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
  
  CREATE PROC [dbo].[Sp_SCPGetInventoryVsCOGS] 

  AS BEGIN
  
  DECLARE @STOCK_VALUE AS MONEY, @COGS AS MONEY	
   	
	SELECT @STOCK_VALUE=SUM(STOCK_VALUE) FROM
	(
	    SELECT SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,(ISNULL((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
		WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=SCPTnStock_M.WraehouseId AND BatchNo=SCPTnStock_M.BatchNo 
		AND CAST(CreatedDate as date) <= EOMONTH(dateadd(m, -1,GETDATE())) ORDER BY CreatedDate DESC),0)*(CASE 
		WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode --AND WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D WHERE SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode 
		                          AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
   		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
		WHERE SCPStItem_M.IsActive=1 AND ItemTypeId=2 
		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,SCPTnGoodReceiptNote_D.ItemRate 
	)TMP 

	SELECT @COGS=SUM(COGS-COGS_REFUND) FROM
    (
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)
	    AND EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode
		AND CAST(PD.CreatedDate AS DATE) BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)
	    AND EOMONTH(dateadd(m, -1,GETDATE()))
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
     )TMP

	 SELECT @COGS/@STOCK_VALUE

	 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetInventoryVsCOGSForDashboard]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



	 CREATE PROC [dbo].[Sp_SCPGetInventoryVsCOGSForDashboard] 

  AS BEGIN
  
  DECLARE @STOCK_VALUE AS MONEY, @COGS AS MONEY	, @PERCENTAGE_AVG_COGS AS VARCHAR(10)
   	
	SELECT @STOCK_VALUE=SUM(STOCK_VALUE) FROM
	(
	    SELECT SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,(ISNULL((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
		WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=SCPTnStock_M.WraehouseId AND BatchNo=SCPTnStock_M.BatchNo 
		AND CAST(CreatedDate as date) <= CAST(GETDATE()-1 AS DATE) ORDER BY CreatedDate DESC),0)*(CASE 
		WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode --AND WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnPharmacyIssuance_D WHERE SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode 
		                          AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
   		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
		WHERE SCPStItem_M.IsActive=1 AND ItemTypeId=2 
		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,SCPTnGoodReceiptNote_D.ItemRate 
	)TMP 

	SELECT @COGS=SUM(COGS-COGS_REFUND) FROM
    (
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)  AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode
		AND CAST(PD.CreatedDate AS DATE) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
     )TMP

	SELECT @PERCENTAGE_AVG_COGS = '1.2%' 

	 SELECT CASE WHEN @COGS!=0 THEN format(@COGS/@STOCK_VALUE,'##.##') ELSE format(0,'##.##') END as AVG_INVENTORY_VS_COGS , 
	 @PERCENTAGE_AVG_COGS AS PERCENTAGE_INV_VS_COGS

	 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetIssuanceItemList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceItemList]
@WraehouseId as int

AS
BEGIN
    SELECT Distinct x.ItemCode, x.ItemName FROM SCPStItem_M x 
	INNER JOIN SCPStItem_D_WraehouseName y ON y.ItemCode = x.ItemCode
	inner join SCPTnStock_M b on b.ItemCode=x.ItemCode and b.WraehouseId=@WraehouseId AND B.CurrentStock > 0
	where x.IsActive=1
END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetIssuanceReceivingForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceReceivingForSearch]
@Search as varchar(50)
AS
BEGIN
	select TRNSCTN_ID,SCPStWraehouseName.WraehouseName as FromWarehouseId ,(select WraehouseName from SCPStWraehouseName where WraehouseId=SCPTnPharmacyReceiving_M.ToWarehouseId) as ToWarehouseId,
	TRNSCTN_DATE,PharmacyIssuanceId from SCPTnPharmacyReceiving_M INNER JOIN SCPStWraehouseName ON SCPTnPharmacyReceiving_M.FromWarehouseId = SCPStWraehouseName.WraehouseId
	where SCPTnPharmacyReceiving_M.TRNSCTN_ID like '%'+@Search+'%' 
	ORDER BY TRNSCTN_ID DESC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItem]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItem]
@ItemCode as varchar(50)
AS
BEGIN
	SELECT Isnull(SCPStItem_M.ItemName,0) as ItemName,Isnull(SCPStItem_M.MedicalNeedItem,0) as MedicalNeedItem, 
	Isnull(SCPStItem_M.ExpiryCategoryId,0) as ExpiryCategoryId,Isnull(SCPStItem_M.ItemTypeId,0) as ItemTypeId, Isnull(SCPStItem_M.ClassId,0) as ClassId, 
    Isnull(SCPStItem_M.SubClassId,0) as SubClassId,Isnull(SCPStItem_M.CategoryId,0) as CategoryId, Isnull(SCPStItem_M.SubCategoryId,0) as SubCategoryId, 
	Isnull(SCPStItem_M.GenericId,0) as GenericId,Isnull(SCPStItem_M.DosageFormId,0) as DosageFormId, Isnull(SCPStItem_M.FormularyId,0) as FormularyId, 
	SCPStFormulary.FormularyName,Isnull(SCPStItem_M.PackingQuantity,0) as PackingQuantity, Isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,Isnull(SCPStItem_M.ItemUnit,0) as ItemUnit, 
	Isnull(SCPStItem_M.ManufacturerId,0) as ManufacturerId, Isnull(SCPStItem_M.RouteOfAdministrationId,0) as RouteOfAdministrationId, Isnull(SCPStItem_M.SignaId,0) as SignaId,
	Isnull(SCPStItem_M.StrengthId,0) as StrengthId, Isnull(SCPStItem_M.Pneumonics,0) as Pneumonics,Isnull(SCPStRate.SalePrice,0) as SalePrice,
	Isnull( SCPStRate.CostPrice,0) as CostPrice, Isnull(SCPStRate.TradePrice,0) as TradePrice, Isnull(SCPStRate.Discount,0) as Discount,
	CASE WHEN SCPStRate.FromDate IS NULL THEN CONVERT(VARCHAR(30),GETDATE(),121) ELSE CONVERT(VARCHAR(30), SCPStRate.FromDate, 121) END AS FromDate,
	CASE WHEN SCPStRate.ToDate IS NULL THEN CONVERT(VARCHAR(30),DATEADD(YEAR,3,GETDATE()),121) ELSE CONVERT(VARCHAR(30), SCPStRate.ToDate, 121) END AS ToDate,
	SCPStItem_M.IsActive FROM SCPStItem_M 
	LEFT OUTER JOIN SCPStFormulary ON SCPStFormulary.FormularyId=SCPStItem_M.FormularyId
	LEFT OUTER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode
    and SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate where CONVERT(date, getdate()) between 
	FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)	where SCPStItem_M.ItemCode=@ItemCode
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemAllBatchNoStock]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemAllBatchNoStock]

	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	SET NOCOUNT ON;

	SELECT STOCK.BatchNo, STOCK.CurrentStock
	 FROM SCPTnStock_M STOCK
		WHERE STOCK.ItemCode = @ItemCode AND STOCK.WraehouseId = @WraehouseId AND STOCK.CurrentStock != 0
  
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemBatchNoes]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemBatchNoes]
@ItemId as varchar(50)	,
@WraehouseId as int
AS
BEGIN
	SELECT distinct I.BatchNo AS BatchNo,I.BatchNo AS BatchNo
    FROM SCPTnStock_M I
    WHERE I.ItemCode=@ItemId and WraehouseId=@WraehouseId
	and I.CurrentStock>0
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemByPneumonicsForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetItemByPneumonicsForSearch]
(
@PNUMONCS VARCHAR(50)
)
AS
BEGIN
SELECT ItemCode,ItemName 
FROM SCPStItem_M  M
WHERE M.Pneumonics LIKE '%'+@PNUMONCS+ '%' AND IsActive=1
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemByShelf]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByShelf]
@ShelfSetupID as int
AS
BEGIN
	SELECT ShelfId,ItemCode,WraehouseId,IsActive
    FROM SCPStItem_D_Shelf where ItemShelfMappingId = @ShelfSetupID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemBySupplier]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetItemBySupplier]
@paramSupplierId AS INT
AS
BEGIN
SELECT  ItemMaster.ItemCode,
		ItemMaster.ItemName AS ItemName
	    FROM [dbo].[SCPStItem_D_Supplier] AS ItemSupp
INNER JOIN [dbo].[SCPStItem_M] AS ItemMaster ON ItemSupp.ItemCode = ItemMaster.ItemCode
WHERE ItemSupp.SupplierId = @paramSupplierId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemByTypeForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByTypeForSearch]
@SearchID as varchar(50),
@ItemType as int
AS
BEGIN
	 SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStItemType.ItemTypeName, isnull(SCPStDosage.DosageName,'') as DosageName,
	isnull(SCPStManufactutrer.ManufacturerName,'') as ManufacturerName FROM SCPStItem_M 
	INNER JOIN SCPStItemType ON SCPStItem_M.ItemTypeId = SCPStItemType.ItemTypeId AND SCPStItem_M.ItemTypeId=@ItemType
	LEFT OUTER JOIN SCPStDosage ON SCPStItem_M.DosageFormId = SCPStDosage.DosageId 
	LEFT OUTER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId where
	SCPStItem_M.ItemName like '%'+@SearchID+'%' OR SCPStItem_M.ItemCode like '%'+@SearchID+'%' order by SCPStItem_M.ItemCode desc
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemByWraehouseNameForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByWraehouseNameForSearch]
@WraehouseId as int,
@SearchID as varchar(50)
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M INNER JOIN SCPStItem_D_WraehouseName 
	ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND SCPStItem_M.IsActive=1
	AND SCPStItem_M.ItemName LIKE '%'+@SearchID+'%' order by SCPStItem_M.ItemName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemByWraehouseNameShelf]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByWraehouseNameShelf]

@shelfId as int,
@WraehouseId as int
AS
BEGIN
 
	--SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPTnStock_D.ItemBalance, SCPStRate.TradePrice
 --   FROM SCPStItem_M INNER JOIN SCPTnStock_D ON SCPStItem_M.ItemCode = SCPTnStock_D.ItemCode INNER JOIN
	--SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ITM_CODE and SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0)
	--from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ITM_CODE=SCPStItem_M.ItemCode)
	--INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode where SCPStItem_D_Shelf.ShelfId=@shelfId
	--and SCPTnStock_D.WraehouseId=@WraehouseId order by SCPStItem_M.ItemCode

	--SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, sum(isnull(SCPTnStock_D.ItemBalance,0)) as ItemBalance, 
 --   isnull(SCPStRate.TradePrice,0) as TradePrice FROM SCPStItem_M INNER JOIN SCPTnStock_D ON SCPTnStock_D.ItemCode = SCPStItem_M.ItemCode AND 
	--isnull(SCPTnStock_D.StockId,0)=(select  ISNULL(max(StockId),0) from SCPTnStock_D iv where SCPTnStock_D.ItemCode=iv.ItemCode and SCPTnStock_D.BatchNo=iv.BatchNo) 
	--INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and isnull(SCPStRate.ItemRateId,0)=(select isnull(Max(ItemRateId),0)
	--from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	--INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId  
	--where SCPTnStock_D.WraehouseId=@WraehouseId group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPStRate.TradePrice
	
----		Declare @ItemType as int 
----    Set @ItemType = (select ItemTypeId from SCPStWraehouseName where WraehouseId=@WraehouseId)

----if(@ItemType = 1)
----    SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, ISnull((SELECT TOP 1 STOCK.CurrentStock FROM SCPTnStock_M STOCK
----	WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1 ORDER 
----	BY STOCK.ID DESC),0) as ItemBalance, isnull(SCPStRate.TradePrice,0) as TradePrice FROM SCPStItem_M INNER JOIN SCPStRate 
----	ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and isnull(SCPStRate.ItemRateId,0)=(select isnull(Max(ItemRateId),0) 
----	from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode) 
----	Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
----	INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId
----    WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND ISnull(( SELECT TOP 1 STOCK.CurrentStock FROM SCPTnStock_M STOCK
----	WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1 ORDER 
----	BY STOCK.ID DESC),0)>0 group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPStRate.TradePrice

----ELSE if(@ItemType = 2)
 
----	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, ISnull((SELECT Sum(STOCK.CurrentStock) as CurrentStock FROM SCPTnStock_M STOCK 
----	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1),0) as ItemBalance, 
----    isnull(SCPStRate.TradePrice,0) as TradePrice FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
----	isnull(SCPStRate.ItemRateId,0)=(select isnull(Max(ItemRateId),0) from SCPStRate where CONVERT(date, getdate()) 
----	between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
----	 Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
----	INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId
----	WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND
----	ISnull((SELECT Sum(STOCK.CurrentStock) as CurrentStock FROM SCPTnStock_M STOCK 
----	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1),0)>0
----	group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPStRate.TradePrice 



SELECT  ItemCode,ItemName,BatchNo,ItemBalance, TradePrice FROM (
    SELECT X.ItemCode,ItemName,X.BatchNo,ItemBalance, CASE WHEN X.BatchNo = '0' THEN CostPrice
   ELSE CASE WHEN ItemRate IS NULL THEN CostPrice ELSE ItemRate END END AS TradePrice FROM (
	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, STOCK.BatchNo, STOCK.CreatedDate
	, STOCK.CurrentStock as ItemBalance FROM SCPStItem_M 
	Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode AND WraehouseId =@WraehouseId
	INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId
	INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.WraehouseId = @WraehouseId AND STOCK.IsActive = 1
    WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1 AND CurrentStock>0
	group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName, STOCK.BatchNo, STOCK.CurrentStock, STOCK.CreatedDate
	)x
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON X.ItemCode = SCPTnGoodReceiptNote_D.ItemCode AND X.BatchNo = SCPTnGoodReceiptNote_D.BatchNo
	INNER JOIN SCPStRate ON X.ItemCode = SCPStRate.ItemCode  AND SCPStRate.FromDate <= X.CreatedDate and SCPStRate.ToDate >= X.CreatedDate 
	)Y --WHERE TradePrice IS NOT NULL
	
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemClass]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemClass]
@ItemId as varchar(50)
AS
BEGIN
	 select ClassId from SCPStItem_M where ItemCode=@ItemId and IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemCurrentStock]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemCurrentStock]
	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	SET NOCOUNT ON;

	--SELECT TOP 1 STOCK.CurrentStock 
	--FROM SCPTnStock_M STOCK
	--WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = @ItemCode
	--	 AND STOCK.IsActive = 1
	--ORDER BY STOCK.ID DESC
	
    SELECT Sum(STOCK.CurrentStock) as CurrentStock FROM SCPTnStock_M STOCK
	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = @ItemCode 
	AND STOCK.IsActive = 1 AND STOCK.CurrentStock != 0

    
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemDeadOnZeroCount]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemDeadOnZeroCount] 
@WraehouseName as int
AS
BEGIN   SELECT 0 as ItemsonZero
		--SELECT distinct COUNT(*) OVER (PARTITION BY 1) as ItemsonZero  FROM 
		--(
		--SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		--left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		--where SCPStItem_M.IsActive=1 AND FormularyId!=0
		--GROUP BY SCPStItem_M.ItemCode,ItemName
		--)TMP
		--WHERE ItemCode IN(
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--   	UNION ALL
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)
		--GROUP BY ItemCode,ItemName,CurrentStock HAVING CurrentStock=0  ---CostPrice

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemDiscardForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemDiscardForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
SELECT a.TRANSC_ID, a.TRANSC_DT,b.WraehouseName
FROM  SCPTnItemDiscard_M as a inner join SCPStWraehouseName as b on a.WraehouseId=b.WraehouseId
 where a.TRANSC_ID LIKE '%'+@Trnsctn_ID+'%' or a.TRANSC_DT  like '%'+@Trnsctn_ID+'%' 
 or b.WraehouseName like '%'+@Trnsctn_ID+'%'
 ORDER BY A.TRANSC_ID DESC
END














GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemExpiryCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetItemExpiryCategory]
@ITEM_ID AS VARCHAR(50)
AS BEGIN
		SELECT CASE WHEN ST.TimeDurationType='Month' THEN DATEADD(MONTH,ExpiryDurationFrom,GETDATE()) 
		WHEN ST.TimeDurationType='Year' THEN DATEADD(YEAR,ExpiryDurationFrom,GETDATE()) 
		ELSE DATEADD(DAY,ExpiryDurationFrom,GETDATE()) END AS EXPR_FROM,
		CASE WHEN DT.TimeDurationType='Month' THEN DATEADD(MONTH,ExpiryDurationTo,GETDATE()) 
		WHEN DT.TimeDurationType='Year' THEN DATEADD(YEAR,ExpiryDurationTo,GETDATE()) 
		ELSE DATEADD(DAY,ExpiryDurationTo,GETDATE()) END AS EXPR_TO FROM SCPStItem_M CC
		INNER JOIN SCPStExpiryCategory EXPR ON EXPR.ExpiryCategoryId = CC.ExpiryCategoryId
		INNER JOIN SCPStTimeType ST ON ST.TimeDurationTypeId = ExpiryDurationFromType
		INNER JOIN SCPStTimeType DT ON DT.TimeDurationTypeId = ExpiryDurationToType
		WHERE ItemCode=@ITEM_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemForReturnToSupplier]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemForReturnToSupplier]
@ItemId as varchar(50),
@BatchNo as varchar(50),
@WraehouseId as int
AS
BEGIN
	SELECT C.CurrentStock as ItemBalance,b.ItemRate FROM SCPTnStock_M C
inner join SCPTnPurchaseOrder_D b on b.ItemCode=C.ItemCode
WHERE C.BatchNo = @BatchNo AND C.WraehouseId = @WraehouseId AND b.ItemCode = @ItemId
--ORDER BY C.StockId DESC

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemForSearch]
@SearchID as varchar(50)

AS
BEGIN
	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStItemType.ItemTypeName, isnull(SCPStDosage.DosageName,'') as DosageName,
	isnull(SCPStManufactutrer.ManufacturerName,'') as ManufacturerName FROM SCPStItem_M INNER JOIN SCPStItemType ON 
	SCPStItem_M.ItemTypeId = SCPStItemType.ItemTypeId LEFT OUTER JOIN SCPStDosage ON SCPStItem_M.DosageFormId = SCPStDosage.DosageId 
	LEFT OUTER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId where SCPStItem_M.ItemName 
	like '%'+@SearchID+'%' OR SCPStItem_M.ItemCode like '%'+@SearchID+'%' order by SCPStItem_M.ItemCode desc
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemList]

AS
BEGIN
	select ItemCode,ItemName from SCPStItem_M where IsActive=1 order by ItemName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemListByType]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemListByType]
@ItemTypeId int
AS
BEGIN

	SET NOCOUNT ON;
		select ItemCode, ItemName from SCPStItem_M
     where IsActive=1 and ItemTypeId=@ItemTypeId order by ItemName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemListByWraehouseName]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemListByWraehouseName] 
@WraehouseId as int
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M 
	INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
	order by SCPStItem_M.ItemName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemOnZeroCount]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPGetItemOnZeroCount]

AS BEGIN

SELECT CAST(SUM(POS_ZERO) AS VARCHAR(50))+' %' POS_ZERO,CAST(SUM(MSS_ZERO) AS VARCHAR(50))+' %' MSS_ZERO 
FROM(
	SELECT CASE WHEN WraehouseId=3 THEN ROUND(CAST(SUM(ITEM_ZERO) AS FLOAT)*100/CAST(COUNT(ItemCode) AS FLOAT),0) END AS POS_ZERO,
	CASE WHEN WraehouseId=10 THEN ROUND(CAST(SUM(ITEM_ZERO) AS FLOAT)*100/CAST(COUNT(ItemCode) AS FLOAT),0) END AS MSS_ZERO 
	FROM(
		SELECT INV.WraehouseId,CC.ItemCode,
		CASE WHEN SUM(CurrentStock)>0 THEN 0 ELSE 1 END AS ITEM_ZERO FROM SCPStItem_M CC
		INNER JOIN SCPTnStock_M INV ON INV.ItemCode = CC.ItemCode 
		WHERE CC.IsActive=1 AND CC.FormularyId!=0
		GROUP BY INV.WraehouseId,CC.ItemCode
	)TMP GROUP BY WraehouseId
)TMPP

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemPneumonicsByWraehouseNameForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemPneumonicsByWraehouseNameForSearch] 
@WraehouseId as int,
@SearchID as varchar(50)
AS
BEGIN
     
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.Pneumonics+' || '+SCPStItem_M.ItemName as Pneumonics FROM SCPStItem_M 
	INNER JOIN SCPStItem_D_WraehouseName	ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND CONVERT(date, getdate()) BETWEEN FromDate and ToDate
	where SCPStItem_M.IsActive=1 AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND SCPStItem_M.Pneumonics LIKE ''+@SearchID+'%' 
	OR SCPStItem_M.ItemName LIKE ''+@SearchID+'%' 
    

	--SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.Pneumonics FROM SCPStItem_M INNER JOIN SCPStItem_D_WraehouseName 
	--ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
	--order by SCPStItem_M.Pneumonics
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemRate]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemRate]
@ItemCode AS VARCHAR(50)
AS
BEGIN
	 SELECT SCPStItem_M.ItemCode,ItemName,ISNULL(TradePrice,0) TradePrice,ISNULL(CostPrice,0) CostPrice,ISNULL(SalePrice,0) SalePrice,
	 ISNULL(Discount,0) Discount,ISNULL(FORMAT(FromDate,'dd-MM-yyyy'),'01-01-0001') AS FromDate,
	 ISNULL(FORMAT(ToDate,'dd-MM-yyyy'),'01-01-0001') AS ToDate FROM SCPStItem_M 
	 LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND SCPStRate.ItemRateId=(SELECT ISNULL(Max(CRP_D.ItemRateId),0) 
	 FROM SCPStRate CRP_D WHERE CONVERT(date, GETDATE()) BETWEEN FromDate AND ToDate AND CRP_D.ItemCode = SCPStItem_M.ItemCode)
	 WHERE SCPStItem_M.ItemCode=@ItemCode and SCPStItem_M.IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemRateChange]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetItemRateChange]
(
@ITEM_ID AS varchar(50))
AS
BEGIN
SELECT c.ItemRateId,c.ItemCode,c.CreatedDate,C.IsActive,C.FromDate,C.SalePrice,C.ToDate,C.TradePrice,C.CostPrice,M.ItemName,C.Discount
FROM SCPStRate C ,SCPStItem_M M
WHERE C.ItemRateId=@ITEM_ID AND C.ItemCode=M.ItemCode
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemRateForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetItemRateForSearch]
(
@name VARCHAR(50)

)
AS
BEGIN
--select c.ItemRateId,C.ITM_CODE,P_M.ItemName,C.TradePrice,C.CostPrice,C.SalePrice,C.FromDate,C.ToDate,C.IsActive
--from  SCPStRate c
--INNER JOIN SCPStItem_M P_M ON P_M.ItemCode =c.ITM_CODE
--WHERE P_M.ItemName LIKE '%'+@name+ '%' 
select c.ItemRateId,C.ItemCode,P_M.ItemName,C.TradePrice,C.CostPrice,C.SalePrice,convert(date,C.FromDate)as FromDate ,convert(date,C.ToDate) as ToDate ,C.IsActive
from  SCPStRate c
INNER JOIN SCPStItem_M P_M ON P_M.ItemCode =c.ItemCode 
WHERE P_M.ItemName LIKE '%'+@name+ '%' and ItemRateId=(select max(ItemRateId)from SCPStRate where c.ItemCode=ItemCode)


END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemRateOnForPO]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[Sp_SCPGetItemRateOnForPO]
@ITemId as varchar(50),
@Price as varchar(50)
AS
BEGIN
if(@Price='PP')
begin
	SELECT SCPStItem_M.ItemCode, SCPStRate.CostPrice as Prize
	FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
	SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	where SCPStItem_M.ItemCode=@ITemId and SCPStItem_M.IsActive=1


  end
  else
  begin
SELECT SCPStItem_M.ItemCode,SCPStRate.TradePrice as Prize
	FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
	SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	where SCPStItem_M.ItemCode=@ITemId and SCPStItem_M.IsActive=1


END


end










GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemRatesbyTypeManufacturer]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemRatesbyTypeManufacturer]
@ItemTypeId  AS INT,
@ManufacturerId AS INT
AS
BEGIN
     SELECT SCPStItem_M.ItemCode,ItemName,TradePrice,CostPrice,SalePrice,Discount,FORMAT(FromDate,'dd-MM-yyyy') AS FromDate,
	 FORMAT(ToDate,'dd-MM-yyyy') AS ToDate FROM SCPStItem_M 
	 INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode  AND SCPStRate.ItemRateId=(SELECT ISNULL(Max(CRP_D.ItemRateId),0) 
	 FROM SCPStRate CRP_D WHERE CONVERT(date, GETDATE()) BETWEEN FromDate AND ToDate AND CRP_D.ItemCode = SCPStItem_M.ItemCode)
	 WHERE ManufacturerId=@ManufacturerId AND ItemTypeId=@ItemTypeId and SCPStItem_M.IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemRatesbyTypeSupplier]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemRatesbyTypeSupplier]
@ItemTypeId AS INT,
@SupplierId AS INT
AS
BEGIN
	 SELECT SCPStItem_M.ItemCode,ItemName,TradePrice,CostPrice,SalePrice,Discount,FORMAT(FromDate,'dd-MM-yyyy') AS FromDate,
	 FORMAT(ToDate,'dd-MM-yyyy') AS ToDate FROM SCPStItem_M 
	 INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND SCPStRate.ItemRateId=(SELECT ISNULL(Max(CRP_D.ItemRateId),0) 
	 FROM SCPStRate CRP_D WHERE CONVERT(date, GETDATE()) BETWEEN FromDate AND ToDate AND CRP_D.ItemCode = SCPStItem_M.ItemCode)
	 INNER JOIN SCPStItem_D_Supplier ON SCPStItem_D_Supplier.ItemCode = SCPStItem_M.ItemCode WHERE SupplierId=@SupplierId AND ItemTypeId=@ItemTypeId
	 and SCPStItem_M.IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemShelf]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemShelf]
@itemCode AS VARCHAR(50)
AS
BEGIN
	 --SELECT SCPStItem_D_WraehouseName.WraehouseId,isnull(ShelfId,0) AS ShelfId FROM SCPStItem_D_WraehouseName 
	 --LEFT OUTER JOIN SCPStItem_D_Shelf ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_D_Shelf.ItemCode AND 
	 --SCPStItem_D_Shelf.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	  SELECT SCPStItem_D_WraehouseName.WraehouseId,isnull(SCPStItem_D_Shelf.ShelfId,0) AS ShelfId,
			isnull(SCPStShelf.RackId,0) AS RackId
 		FROM SCPStItem_D_WraehouseName 
	 LEFT OUTER JOIN SCPStItem_D_Shelf ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_D_Shelf.ItemCode AND 
	 SCPStItem_D_Shelf.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	 left outer join SCPStShelf on SCPStItem_D_Shelf.ShelfId = SCPStShelf.ShelfId
	 WHERE SCPStItem_D_WraehouseName.ItemCode=@itemCode
		 AND SCPStItem_D_Shelf.CreatedDate = (select isnull(Max(CreatedDate),0) from SCPStItem_D_Shelf RS where 
	  RS.ItemCode=SCPStItem_D_Shelf.ItemCode and rs.WraehouseId = SCPStItem_D_Shelf.WraehouseId)
     order by SCPStItem_D_WraehouseName.WraehouseId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemShelfForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetItemShelfForSearch]
@shlef as varchar(50),
@SHLFID as int
AS
BEGIN

  SELECT SCPStItem_D_Shelf.ItemShelfMappingId, SCPStShelf.ShelfName,SCPStItem_M.ItemName ,SCPStShelf.ShelfId, SCPStItem_D_Shelf.IsActive FROM SCPStItem_M 
  INNER JOIN SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode 
  INNER JOIN SCPStShelf ON SCPStItem_D_Shelf.ShelfId = SCPStShelf.ShelfId 
  INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
   AND  SCPStItem_D_Shelf.ShelfId =@SHLFID
  --INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId=SCPStItem_D_Shelf.WraehouseId 
  --AND SCPStItem_D_Shelf.WraehouseId=3 
  WHERE SCPStItem_M.ItemName LIKE '%'+@shlef+'%' OR SCPStShelf.ShelfName LIKE '%'+@shlef+'%' 
  --order by SCPStItem_D_Shelf.WraehouseId,SCPStItem_D_Shelf.ItemShelfMappingId, SCPStShelf.ShelfName
  ORDER BY SCPStItem_D_Shelf.ItemShelfMappingId Desc

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemsOnZeroCount]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemsOnZeroCount] 
@WraehouseName as int
AS
BEGIN      
		SELECT distinct COUNT(*) OVER (PARTITION BY 1) as ItemsonZero  FROM 
		(
		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode,ItemName
		)TMP WHERE CurrentStock=0
		--WHERE ItemCode NOT IN(
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--   	UNION ALL
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)
		--GROUP BY ItemCode,ItemName,CurrentStock HAVING CurrentStock=0  ---CostPrice

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemsOnZeroCountForDashboard]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[Sp_SCPGetItemsOnZeroCountForDashboard] 
@WraehouseName as int
AS
BEGIN     

declare @items_zero as int ,@item_zero_percentage as decimal ,@item_total as decimal
		SELECT  distinct @items_zero = COUNT(*) OVER (PARTITION BY 1)  FROM 
		(
		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode,ItemName
		)TMP WHERE CurrentStock=0

		SELECT  distinct @item_total = COUNT(*) OVER (PARTITION BY 1)  FROM 
		(
		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode,ItemName
		)TMP 



		Select convert(varchar(10),@items_zero) as item_zero , format(@items_zero/@item_total,'##.##%') as percentage
		--WHERE ItemCode NOT IN(
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--   	UNION ALL
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)
		--GROUP BY ItemCode,ItemName,CurrentStock HAVING CurrentStock=0  ---CostPrice

END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemStock]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemStock]
	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	 
	SELECT ISNULL(Sum(STOCK.CurrentStock),0) as CurrentStock FROM SCPTnStock_M STOCK
	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = @ItemCode AND STOCK.IsActive = 1 --AND STOCK.CurrentStock != 0
    
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemType]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemType]
@TypeId as int
AS
BEGIN
      select ItemTypeName,IsActive from SCPStItemType where ItemTypeId=@TypeId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemTypeByWraehouseName]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeByWraehouseName]
@WraehouseId as int
AS
BEGIN
	  select SCPStItemType.ItemTypeId,SCPStItemType.ItemTypeName from SCPStItemType INNER JOIN SCPStWraehouseName ON 
	  SCPStWraehouseName.ItemTypeId=SCPStItemType.ItemTypeId where SCPStWraehouseName.WraehouseId=@WraehouseId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemTypeForRate]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeForRate]
@ItemTypeId AS INT
AS
BEGIN
	SELECT AlllowSale FROM SCPStItemType WHERE ItemTypeId=@ItemTypeId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemTypeForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeForSearch]
	
	@ItemType as varchar(50)
AS
BEGIN
	 SELECT ItemTypeId,ItemTypeName,IsActive
     FROM SCPStItemType WHERE ItemTypeId LIKE '%'+@ItemType+'%' OR ItemTypeName LIKE '%'+@ItemType+'%' 
	 ORDER BY ItemTypeId DESC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemTypeList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeList]
AS
BEGIN
	select ItemTypeId,ItemTypeName from SCPStItemType 
     where IsActive=1 order by ItemTypeName
 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemVendors]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemVendors]
@itemId as varchar(50)
AS
BEGIN
	SELECT SupplierId, DefaultVendor, IsActive
FROM SCPStItem_D_Supplier where ItemCode=@itemId 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetkit_M]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[Sp_SCPGetkit_M]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.KitName,a.KitCategoryId,a.IsActive
FROM  SCPStKit_M as a 
where a.KitId=@Trnsctn_ID and a.IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetKitCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetKitCategory]
@KitCatId as int
AS
BEGIN
      select KitCategoryId,IsActive from SCPStKitCategory where KitCategoryIdegoryId=@KitCatId
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetKitCategoryByPatientCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetKitCategoryByPatientCategory]
@PtCateId as int
AS
BEGIN
	 SELECT KitCategoryIdegoryId,KitCategoryId FROM SCPStKitCategory WHERE IsActive=1 AND PatientCategoryId=@PtCateId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetKitCategoryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetKitCategoryForSearch]
	@PtCateId as int,
	@KitCate as varchar(50)
AS
BEGIN
	 SELECT KitCategoryIdegoryId,KitCategoryId,IsActive
     FROM SCPStKitCategory WHERE  PatientCategoryId=@PtCateId AND (KitCategoryIdegoryId LIKE '%'+@KitCate+'%' OR KitCategoryId LIKE '%'+@KitCate+'%')
	 ORDER BY KitCategoryIdegoryId DESC
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetkitForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetkitForSearch]
@Trnsctn_ID as varchar(50),
@KitCatId as INT
AS
BEGIN
SELECT a.KitId,a.KitName FROM SCPStKit_M as a 
where KitCategoryId=@KitCatId AND (a.KitId LIKE '%'+@Trnsctn_ID+'%' or a.KitName like '%'+@Trnsctn_ID+'%')
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetKitList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetKitList]
@PatientCateId as int
AS
BEGIN
	 select KitId,KitName from SCPStKit_M
     inner join SCPStKitCategory on SCPStKitCategory.KitCategoryIdegoryId = SCPStKit_M.KitCategoryId
     where SCPStKit_M.IsActive=1 and SCPStKitCategory.PatientCategoryId=@PatientCateId
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetLastDayDemandSummary]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetLastDayDemandSummary] 
AS
BEGIN
		  DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
		  --SELECT @REPORT_DATE
  
   				select DemandType, count(*) value from SCPTnDemand_M
				where IsActive =1 
				and
				CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
				group by DemandType,CAST(CreatedDate AS date)
				order by DemandType,CAST(CreatedDate AS date)
		
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetLastDayDemandvsIssuence]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetLastDayDemandvsIssuence] 

AS
BEGIN


--DECLARE  @FROM_DT AS VARCHAR(50)=FORMAT(GETDATE()-1, 'dddd') ,@ToDate AS VARCHAR(50)=FORMAT(GETDATE()-1, 'dddd')

--SET @FROM_DT = case @FROM_DT when 	'Sunday' then getdate() -2 else getdate() - 1 end 
--set @ToDate = case @ToDate when 'Sunday' then getdate() - 2 else getdate() -1 end

	      DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
SELECT ISSU_ITEM,count(ItemCode) AS DMND_ITM FROM

(

 SELECT ItemCode,COUNT(ItemCode) DMND_ITM,(SELECT COUNT(ItemCode) FROM

       (SELECT DISTINCT ItemCode FROM SCPTnPharmacyIssuance_D WHERE CAST(SCPTnPharmacyIssuance_D.CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)

       )TMPP) AS ISSU_ITEM

FROM SCPTnDemand_D WHERE CAST(SCPTnDemand_D.CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)

GROUP BY ItemCode

)TMP group by ISSU_ITEM


END

--SELECT SUM(DMND_ITM) AS DMND_ITM,SUM(ISSU_ITEM) AS ISSU_ITEM FROM

--(

--SELECT PARENT_TRNSCTN_ID,COUNT(ItemCode) DMND_ITM,

--(SELECT  COUNT(ItemCode) FROM SCPTnPharmacyIssuance_D WHERE DemandId=SCPTnDemand_D.PARENT_TRNSCTN_ID) AS ISSU_ITEM

--FROM SCPTnDemand_D WHERE CAST(SCPTnDemand_D.CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)

--GROUP BY PARENT_TRNSCTN_ID

--)TMP
 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetLastDayDemandvsIssuencePercentage]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetLastDayDemandvsIssuencePercentage]

AS BEGIN

	DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
	DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
	DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
	DECLARE @FLAG AS BIT = 0;								  --For loop


	WHILE @FLAG = 0
	BEGIN
		SET @FLAG = 1;
		IF @REPORT_DAY = 1     -- Sunday Condition
		BEGIN 
			SET @FLAG = 0;
			SET @DAYS_DIFF = @DAYS_DIFF +1;
			SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
			SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
		END 
		IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
		BEGIN
			SET @FLAG = 0;
			SET @DAYS_DIFF = @DAYS_DIFF +1;
			SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
			SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
		END
	END

	SELECT CAST((ISSU_ITEM*100)/count(ItemCode) AS VARCHAR(50)) AS DmndVsIssuancePrcntg FROM
	(
		SELECT ItemCode,COUNT(ItemCode) DMND_ITM,(SELECT COUNT(ItemCode) FROM
		(
			SELECT DISTINCT ItemCode FROM SCPTnPharmacyIssuance_D WHERE CAST(SCPTnPharmacyIssuance_D.CreatedDate AS date) 
			BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
			)TMPP
		) AS ISSU_ITEM FROM SCPTnDemand_D WHERE CAST(SCPTnDemand_D.CreatedDate AS date) 
		BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date) GROUP BY ItemCode
	)TMP group by ISSU_ITEM

END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetManufactutrer]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrer]
@ManufacturerId as int
AS
BEGIN
     SELECT ManufacturerName,ManufacturerCategoryId,IsActive
     FROM SCPStManufactutrer  WHERE ManufacturerId=@ManufacturerId 
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetManufactutrerCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerCategory]
@MncftrCatId as int
AS
BEGIN
      select ManufacturerCategoryName,IsActive from SCPStManufactutrerCategory where ManufacturerCategoryId=@MncftrCatId
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetManufactutrerCategoryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerCategoryForSearch]
	
	@MncftrCatName as varchar(50)
AS
BEGIN
	 SELECT ManufacturerCategoryId,ManufacturerCategoryName,IsActive
     FROM SCPStManufactutrerCategory C WHERE ManufacturerCategoryName LIKE '%'+@MncftrCatName+'%' 
	 ORDER BY ManufacturerCategoryId Desc
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetManufactutrerCategoryList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerCategoryList]
AS
BEGIN
	select ManufacturerCategoryId,ManufacturerCategoryName from SCPStManufactutrerCategory
     where IsActive=1 order by ManufacturerCategoryName
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetManufactutrerForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerForSearch]
	@ManufacturerCate_ID as int,
	@Manufacturer_NAME as varchar(50)
AS
BEGIN

     SELECT  C.ManufacturerId, C.ManufacturerName, SCPStManufactutrerCategory.ManufacturerCategoryName, C.IsActive
     FROM  SCPStManufactutrer C INNER JOIN SCPStManufactutrerCategory ON  C.ManufacturerCategoryId = SCPStManufactutrerCategory.ManufacturerCategoryId
	 WHERE C.ManufacturerCategoryId=@ManufacturerCate_ID and C.ManufacturerName LIKE '%'+@Manufacturer_NAME+'%'
	 ORDER BY C.ManufacturerName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetManufactutrerList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerList]
AS
BEGIN
	 select ManufacturerId,ManufacturerName from SCPStManufactutrer where IsActive=1 order by ManufacturerName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetMeasuringUnit]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMeasuringUnit]
@UnitId as int
AS
BEGIN
      select UnitName,IsActive from SCPStMeasuringUnit where UnitId=@UnitId
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetMeasuringUnitForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMeasuringUnitForSearch]
	
	@UnitName as varchar(50)
AS
BEGIN
	 SELECT UnitId,UnitName,IsActive
     FROM SCPStMeasuringUnit C WHERE UnitName LIKE '%'+@UnitName+'%' 
	 ORDER BY UnitId desc
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetMeasuringUnitList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMeasuringUnitList]
	
AS
BEGIN
	  select UnitId,UnitName from SCPStMeasuringUnit where IsActive=1 order by UnitName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetMonthlyGeneralPurchase]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMonthlyGeneralPurchase]
AS
BEGIN

SELECT Year_Month,CreatedDate,TotalPuchase,GnrlPuchase,(GnrlPuchase*100)/TotalPuchase AS GnrlPrchsPrcntg FROM
 (
 SELECT SubString(Convert(Varchar(Max), SCPTnGoodReceiptNote_M.CreatedDate,0), 1, 3) + '-' + Cast(Year(SCPTnGoodReceiptNote_M.CreatedDate) As Varchar(Max)) as Year_Month, 
 right(convert(varchar, SCPTnGoodReceiptNote_M.CreatedDate, 103), 7) as CreatedDate,SUM(SCPTnGoodReceiptNote_M.NetAmount) AS TotalPuchase,isnull((SELECT SUM(NetAmount) FROM SCPTnGoodReceiptNote_M PRC 
 INNER JOIN SCPStSupplier ON SCPStSupplier.SupplierId=PRC.SupplierId WHERE PRC.WraehouseId IN(SELECT WraehouseId FROM SCPStWraehouseName WHERE ItemTypeId=1 AND
 IsActive=1) AND SCPStSupplier.SupplierCategoryId=1 AND SCPStSupplier.IsActive=1 AND right(convert(varchar, PRC.CreatedDate, 103), 7)=right(convert(varchar, SCPTnGoodReceiptNote_M.CreatedDate, 103), 7)),0) 
 AS GnrlPuchase FROM SCPTnGoodReceiptNote_M WHERE SCPTnGoodReceiptNote_M.WraehouseId IN(SELECT WraehouseId FROM SCPStWraehouseName  WHERE ItemTypeId=1 AND IsActive=1)
 AND SCPTnGoodReceiptNote_M.IsActive=1 GROUP BY right(convert(varchar, SCPTnGoodReceiptNote_M.CreatedDate, 103), 7), SubString(Convert(Varchar(Max), SCPTnGoodReceiptNote_M.CreatedDate,0), 1, 3)
 + '-' + Cast(Year(SCPTnGoodReceiptNote_M.CreatedDate) As Varchar(Max))
 )tmp ORDER BY right(convert(varchar, CreatedDate, 103), 7)

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetNamePrefixList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetNamePrefixList]

AS
BEGIN
  select NamePrefixId,NamePrefixName from SCPStNamePrefix where IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetParLevel]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[Sp_SCPGetParLevel]
@lvlId as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   select ParLevelName, IsActive,SerialNo from SCPStParLevel where ParLevelId = @lvlId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetParLevelForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE  [dbo].[Sp_SCPGetParLevelForSearch] 
@PARLVL as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

   	 SELECT ParLevelId,  ParLevelName, IsActive, SerialNo
     FROM SCPStParLevel C WHERE ParLevelName LIKE '%'+ @PARLVL+'%' 
	 ORDER BY ParLevelId Desc 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetParLevelList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetParLevelList]
AS
BEGIN

SELECT ParLevelId,ParLevelName FROM SCPStParLevel WHERE IsActive=1

END 




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetParLevelSequenceForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[Sp_SCPGetParLevelSequenceForSearch] 
@PARLVL as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

   	 SELECT ParLevelId,  ParLevelName, IsActive
     FROM SCPStParLevel C WHERE ParLevelName LIKE '%'+ @PARLVL+'%' AND IsActive=1
	 ORDER BY SerialNo 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetParLevelTransaction]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetParLevelTransaction]
@Trnsctn_ID as varchar(50),
@Item_Id as varchar(50)

AS
BEGIN

IF(@Item_Id = '0')
	SELECT PARLVL.TRNSCTN_ID, TRNSCTN_DATE, ItemName, WraehouseName FROM SCPStParLevelAssignment_M PARLVL 
	INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PARLVL.ItemCode and ITM.IsActive=1
	INNER JOIN SCPStWraehouseName WraehouseName  ON WraehouseName.WraehouseId = PARLVL.WraehouseId
	 where PARLVL.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or ItemName LIKE '%'+@Trnsctn_ID+'%' 
	 order by PARLVL.TRNSCTN_ID desc

IF(@Item_Id != '0')
	 SELECT PARLVL.TRNSCTN_ID, TRNSCTN_DATE, ItemName, WraehouseName FROM SCPStParLevelAssignment_M PARLVL 
	INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PARLVL.ItemCode and ITM.IsActive=1
	INNER JOIN SCPStWraehouseName WraehouseName  ON WraehouseName.WraehouseId = PARLVL.WraehouseId
	 where PARLVL.ItemCode LIKE '%'+@Item_Id+'%' AND PARLVL.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%' 
	  order by PARLVL.TRNSCTN_ID desc
 -- if(@ParentTrnsctnId='0')
 -- Begin

 --  SELECT TRNSCTN_ID,ITM_CODE,ItemName,CRNT_MinLevel,CRNT_MaxLevel,MinLevel,MaxLevel FROM
 -- (
 --   SELECT isnull(CC.TRNSCTN_ID,0) as TRNSCTN_ID,isnull(SCPStItem_M.ItemCode,0) as ITM_CODE, isnull(SCPStItem_M.ItemName,0) as ItemName,
 --   isnull(CC.CRNT_MinLevel,0) as CRNT_MinLevel,  isnull(CC.CRNT_MaxLevel,0) as CRNT_MaxLevel, isnull(CC.MinLevel,0) as MinLevel, 
 --   isnull(CC.MaxLevel,0) as MaxLevel FROM  SCPStItem_M inner join SCPStItem_D_WraehouseName on SCPStItem_D_WraehouseName.ItemCode= SCPStItem_M.ItemCode and 
 --   SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId  left outer JOIN SCPStParLevelAssignment_D CC ON SCPStItem_M.ItemCode = CC.ItemCode and 
 --   cc.PARENT_TRNSCTN_ID=(select isnull(Max(TRNSCTN_ID),0) from SCPStParLevelAssignment_M where CONVERT(date, getdate()) between FromDate 
 --   and ToDate and WraehouseId=SCPStItem_D_WraehouseName.WraehouseId)  
 --  )TMP WHERE ItemName like '%'+@SearchID+'%'

 --END

 --  else

 --BEGIN

 -- SELECT TRNSCTN_ID,ITM_CODE,ItemName,CRNT_MinLevel,CRNT_MaxLevel,MinLevel,MaxLevel FROM
 -- (
 --   SELECT isnull(CC.TRNSCTN_ID,0) as TRNSCTN_ID,isnull(SCPStItem_M.ItemCode,0) as ITM_CODE, isnull(SCPStItem_M.ItemName,0) as ItemName,
 --   isnull(CC.CRNT_MinLevel,0) as CRNT_MinLevel,  isnull(CC.CRNT_MaxLevel,0) as CRNT_MaxLevel, isnull(CC.MinLevel,0) as MinLevel, 
 --   isnull(CC.MaxLevel,0) as MaxLevel FROM  SCPStItem_M inner join SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode and 
 --   SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId left outer JOIN SCPStParLevelAssignment_D CC ON SCPStItem_M.ItemCode = CC.ItemCode and 
 --   cc.PARENT_TRNSCTN_ID=@ParentTrnsctnId  
	-- )TMP where ItemName like '%'+@SearchID+'%'
 --END
 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPartnerForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPGetPartnerForSearch]
 

 @Search as varchar
 

AS
BEGIN

 SET NOCOUNT ON;

select a.PartnerId,a.PartnerName,a.IsActive  from SCPStPartner as a
where a.PartnerName LIKE '%'+@Search+'%' ORDER BY a.PartnerName

END








GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPartnerList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPartnerList]
AS
BEGIN
SELECT PartnerId,PartnerName
FROM SCPStPartner
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[Sp_SCPGetPatientCategory]
(
@PatientCategoryId AS INT)
AS
BEGIN
SELECT C.PatientCategoryName,C.IsActive
FROM SCPStPatientCategory C
WHERE C.PatientCategoryId=@PatientCategoryId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientCategoryForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPatientCategoryForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT PatientCategoryName,PatientCategoryId,IsActive
FROM  SCPStPatientCategory
WHERE PatientCategoryName LIKE '%'+@name+ '%' ORDER BY PatientCategoryId Desc
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientCategoryList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientCategoryList]
AS
BEGIN
	select a.PatientCategoryId,a.PatientCategoryName from SCPStPatientCategory as a
     where a.IsActive=1 order by a.PatientCategoryName
 END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientDataForRefund]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientDataForRefund]
@patId as varchar(50)
AS
BEGIN
	--select PatientIp,Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM,PatientCategoryId,PatientTypeId from SCPTnInPatient
    --   where  PatientIp=@patId
	--select Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM,isnull(PatientCategoryId,0) as PatientCategoryId,
 --   isnull(PatientSubCategoryId,0) as PatientSubCategoryId, isnull(PatientTypeId,0) as PatientTypeId,isnull(CompanyId,0) as CompanyId,
 --   isnull(ConsultantId,0) as ConsultantId,isnull(CareOffCode,0) as CareOffCode,isnull(CareOff,0) as CareOff from SCPTnSale_M
	--where PatientIp=@patId

	select Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM, PatientCategoryId as PatientCategoryId,
    isnull(PatientWard,0) as PatientSubCategoryId, isnull(PatientTypeId,0) as PatientTypeId,isnull(CompanyId,0) as CompanyId,
    isnull(ConsultantId,0) as ConsultantId,isnull(CareOffCode,0) as CareOffCode,
	CAST(isnull(CAST(CareOff AS bigint),0) AS VARCHAR(50)) as CareOff from SCPTnInPatient
	where PatientIp=@patId

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientForSearch]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPatientForSearch]
@Search as varchar(50)
AS
BEGIN
	SELECT DISTINCT (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  AS PatientIp,
	(PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  as PatientIpNO
	FROM  SCPTnInPatient 	WHERE PatientIp LIKE '%'+@Search+'%'  --SCPTnInPatient.Status=1

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientSubCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientSubCategory]
 
   @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.PatientSubCategoryId,a.PatientSubCategoryName,a.IsActive,a.PatientCategoryId,b.PatientCategoryName  from SCPStPatientSubCategory as a inner join SCPStPatientCategory as b on a.PatientCategoryId=b.PatientCategoryId
where b.PatientCategoryId=@ID and a.PatientSubCategoryName LIKE '%'+@Search+'%'
ORDER BY a.PatientSubCategoryId desc

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientSubCategoryByCategory]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientSubCategoryByCategory]
@SCPPatientCatId as int
AS
BEGIN
	select PatientSubCategoryId,PatientSubCategoryName from SCPStPatientSubCategory 
	where PatientCategoryId=@SCPPatientCatId and IsActive=1 order by PatientSubCategoryName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientSubCategoryList]    Script Date: 02/Feb/2020 11:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientSubCategoryList]

AS
BEGIN
	select PatientSubCategoryId,PatientSubCategoryName from SCPStPatientSubCategory where IsActive=1 order by PatientSubCategoryName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPatientType]
(
@PatientTypeId AS INT)
AS
BEGIN
SELECT C.PatientTypeName,C.IsActive
FROM SCPStPatientType C
WHERE C.PatientTypeId=@PatientTypeId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientTypeForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPatientTypeForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT PatientTypeId,PatientTypeName,IsActive
FROM  SCPStPatientType
WHERE PatientTypeName LIKE '%'+@name+ '%' 
ORDER BY PatientTypeName
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPatientTypeList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPatientTypeList] 
AS
BEGIN
SELECT C.PatientTypeId,C.PatientTypeName
FROM SCPStPatientType C WHERE IsActive=1
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPaymentMode]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPaymentMode]
(
@CompanyId AS INT)
AS
BEGIN
SELECT c.ModeOfPaymentId,c.IsActive
FROM SCPStPaymentMode C
WHERE C.ModeOfPaymentId=@CompanyId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPaymentModeForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPaymentModeForSearch]

(@name VARCHAR(50)
)
AS
BEGIN
SELECT C.ModeOfPaymentId,C.ModeOfPaymentId,C.IsActive
FROM  SCPStPaymentMode C
WHERE C.ModeOfPaymentId LIKE '%'+@name+ '%' 
ORDER BY C.ModeOfPaymentId desc
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPaymentTerm]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPaymentTerm]
(
@PAYMENT_ID AS INT)
AS
BEGIN
SELECT C.PaymentTermName,C.IsActive
FROM SCPStPaymentTerm C
WHERE C.PaymentTermId=@PAYMENT_ID
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPaymentTermForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPaymentTermForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.PaymentTermId,C.PaymentTermName,C.IsActive
FROM  SCPStPaymentTerm C
WHERE C.PaymentTermName LIKE '%'+@name+ '%' 
ORDER BY C.PaymentTermName
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPaymentTermList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPaymentTermList]
	
AS
BEGIN
	select PaymentTermId,PaymentTermName from SCPStPaymentTerm where IsActive=1 order by PaymentTermName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPharmacyIssuanceForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPharmacyIssuanceForSearch]
@Search as varchar(50)
AS
BEGIN
	select TRNSCTN_ID,SCPStWraehouseName.WraehouseName as FromWarehouseId ,(select WraehouseName from SCPStWraehouseName where WraehouseId=SCPTnPharmacyIssuance_M.ToWarehouseId) as ToWarehouseId,
	TRNSCTN_DATE from SCPTnPharmacyIssuance_M INNER JOIN SCPStWraehouseName ON SCPTnPharmacyIssuance_M.FromWarehouseId = SCPStWraehouseName.WraehouseId
	where SCPTnPharmacyIssuance_M.TRNSCTN_ID like '%'+@Search+'%' 
	ORDER BY TRNSCTN_ID DESC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPneumonicsListbyType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPneumonicsListbyType]

AS
BEGIN
	select ItemCode,Pneumonics from SCPStItem_M where IsActive=1 and ItemTypeId=2 order by Pneumonics 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchasedItemsForReturnToSupplier]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchasedItemsForReturnToSupplier]
@WraehouseId as int,
@SupplierID as int
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M 
	INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	INNER JOIN SCPStItem_D_Supplier ON SCPStItem_M.ItemCode = SCPStItem_D_Supplier.ItemCode
	--INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	--INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_M.TRNSCTN_ID = SCPTnGoodReceiptNote_D.PARENT_TRNSCTN_ID 
	--AND SCPTnGoodReceiptNote_M.SupplierId=SCPStItem_D_Supplier.SupplierId AND SCPTnGoodReceiptNote_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND SCPStItem_D_Supplier.SupplierId =@SupplierID
	AND SCPStItem_M.IsActive=1
	GROUP BY SCPStItem_M.ItemCode, SCPStItem_M.ItemName
	HAVING SUM(CurrentStock)>0 order by ItemName

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseOrder_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrder_M]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT DISTINCT a.TRNSCTN_ID, 
		   a.TRNSCTN_DATE,
		   a.SupplierId,
		   a.WarehouseId,
		   SCPStWraehouseName.ItemTypeId,
		   a.ItemRate,
		   a.TotalAmount,
		   IsApprove,IsReject,
		   Vendor.SupplierLongName
FROM  SCPTnPurchaseOrder_M as a
INNER JOIN SCPStSupplier AS Vendor ON Vendor.SupplierId = a.SupplierId
INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId = a.WarehouseId
 where a.TRNSCTN_ID=@Trnsctn_ID
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseOrderDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderDiscard_D]
@TransactionId  AS VARCHAR(50)
AS
BEGIN
	 SELECT ItemCode,OrderQty,PendingQty,DiscardQty,RemainingQty,DiscardReasonIdId,DiscardReasonId FROM SCPTnPODiscard_D WHERE PARENT_TRNSCTN_ID=@TransactionId
     AND IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseOrderDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderDiscard_M]
@TransactionId  AS VARCHAR(50)
AS
BEGIN
	  SELECT TRANSCTN_DT,WraehouseId,SupplierId,PurchaseOrderNo FROM SCPTnPODiscard_M WHERE TRANSCTN_ID=@TransactionId
	  AND IsActive=1
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseOrderForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderForSearch]
@Trnsctn_ID as varchar(50),
@paramWraehouseId INT
AS
BEGIN
		SELECT a.TRNSCTN_ID,a.TRNSCTN_DATE,a.SupplierId,a.WarehouseId,y.WraehouseName,x.SupplierShortName,SupplierLongName
FROM  SCPTnPurchaseOrder_M as a		
INNER JOIN SCPStWraehouseName y ON a.WarehouseId= y.WraehouseId
INNER JOIN SCPStSupplier x ON a.SupplierId = x.SupplierId
 where a.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%' AND y.WraehouseId = @paramWraehouseId
 ORDER BY A.TRNSCTN_ID DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseOrderItemRates]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[Sp_SCPGetPurchaseOrderItemRates] 
@SuppId as int,
@WId as varchar(50),
@Price as varchar(50)
AS
BEGIN
if(@Price='PP')
begin
select c.ItemCode,c.ItemName,d.CostPrice as Price,x.SupplierId,z.WraehouseId
from SCPStItem_M as c 
inner join SCPStItem_D_Supplier x on x.ItemCode=c.ItemCode
inner join SCPStItem_D_WraehouseName z on  z.ItemCode=c.ItemCode
inner join SCPStRate d on  c.ItemCode = d.ItemCode and 
	d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode)
WHERE z.WraehouseId=@WId  and x.SupplierId=@SuppId  and x.IsActive=1
  end
  else
  begin
select c.ItemCode,c.ItemName,d.TradePrice as Price,x.SupplierId,z.WraehouseId
from SCPStItem_M as c 
inner join SCPStItem_D_Supplier x on x.ItemCode=c.ItemCode
inner join SCPStItem_D_WraehouseName z on  z.ItemCode=c.ItemCode
inner join SCPStRate d on  c.ItemCode = d.ItemCode and 
	d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode)
WHERE z.WraehouseId=@WId  and x.SupplierId=@SuppId  and x.IsActive=1
END


end



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseRequisitionDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionDiscard_D]
@PARENT_ID AS VARCHAR(50)
AS
BEGIN
	 SELECT ItemCode,RequestedQty,PendingQty,DiscardQty,RemainingQty,DiscardReasonIdId,ISNULL(DiscardReasonId,'') AS DiscardReasonId
	 FROM SCPTnPRDiscard_D WHERE PARENT_TRNSCTN_ID=@PARENT_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseRequisitionDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionDiscard_M] 
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	 SELECT TRANSCTN_DT,WraehouseId,PurchaseRequisitionId FROM SCPTnPRDiscard_M
     WHERE TRANSCTN_ID=@TRNSCTN_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseRequisitionDiscardForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionDiscardForSearch] 
@SEARCH AS VARCHAR(50)
AS
BEGIN
	SELECT TRANSCTN_ID,TRANSCTN_DT,PurchaseRequisitionId,SCPStWraehouseName.WraehouseName FROM SCPTnPRDiscard_M
    INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId=SCPTnPRDiscard_M.WraehouseId WHERE TRANSCTN_ID LIKE '%'+@SEARCH+'%' 
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetPurchaseVsCOGSForDashboard]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[Sp_SCPGetPurchaseVsCOGSForDashboard] 

  AS BEGIN
  
  DECLARE @PURCHASE_VALUE AS MONEY, @COGS AS MONEY	, @PERCENTAGE_AVG_PURCHASE_COGS AS VARCHAR(10)
   	
	select @PURCHASE_VALUE = sum(NetAmount) from SCPTnGoodReceiptNote_M where  CreatedDate between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) and IsActive = 1  and IsApproved =1;

	SELECT @COGS=SUM(COGS-COGS_REFUND) FROM
    (
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode
		AND CAST(PD.CreatedDate AS DATE) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
     )TMP

	SELECT @PERCENTAGE_AVG_PURCHASE_COGS = '1.2%' 

	 SELECT CASE WHEN @COGS!=0 THEN CONVERT(VARCHAR,@COGS/@PURCHASE_VALUE) ELSE CONVERT(VARCHAR,0) END as AVG_PURCHASE_VS_COGS , 
	 @PERCENTAGE_AVG_PURCHASE_COGS AS PERCENTAGE_AVG_PURCHASE_COGS

	 END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetQualification]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetQualification]
(
@QualiId AS INT)
AS
BEGIN
SELECT C.QualificationName,C.IsActive
FROM SCPStQualification C
WHERE C.QualificationId=@QualiId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetQualificationList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetQualificationList]
AS
BEGIN
	select QualificationId,QualificationName from SCPStQualification
     where IsActive=1 order by QualificationName
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetRack]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetRack]
@ParentShlfId as int
AS
BEGIN
      select WraehouseId,RackName,IsActive from SCPStRack
	  where RackId=@ParentShlfId
	  ORDER BY RackId DESC
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetRackByWraehouseName]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetRackByWraehouseName]

@W_ID as bigint
AS
BEGIN
	
	SET NOCOUNT ON;
	SELECT * FROM SCPStRack WHERE WraehouseId = @W_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetRackForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetRackForSearch]
	
	@ShelfParentName as varchar(50)
	,@W_ID bigint
AS
BEGIN


	SELECT RackId, RackName,
	SCPStRack.IsActive, SCPStWraehouseName.WraehouseName
    FROM SCPStRack
	INNER JOIN SCPStWraehouseName ON SCPStRack.WraehouseId = SCPStWraehouseName.WraehouseId 
	WHERE SCPStRack.RackName LIKE '%'+@ShelfParentName+'%' and SCPStRack.WraehouseId=@W_ID 
	 AND SCPStRack.WraehouseId=SCPStWraehouseName.WraehouseId
	ORDER BY RackId DESC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetRateChangePercentage]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   

    CREATE PROC [dbo].[Sp_SCPGetRateChangePercentage]

	AS BEGIN
   
    SELECT ISNULL(COUNT(ItemCode),0) AS RateChange FROM SCPStRate 
	WHERE CAST(CreatedDate AS DATE) 
	BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)
	AND EOMONTH(dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)) 
	AND ((SalePrice-CostPrice)/SalePrice*100)<10

	END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetReasonId]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReasonId]
@ReasonId as int
AS
BEGIN
     SELECT ReasonId,DocumentType,IsActive
     FROM SCPStReasonId  WHERE ReasonId=@ReasonId 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetReasonIdList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReasonIdList]
@DocumentType AS VARCHAR(50)
AS
BEGIN
	SELECT ReasonId,ReasonId FROM SCPStReasonId WHERE DocumentType=@DocumentType AND IsActive=1
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetReturnToStoreForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToStoreForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
SELECT a.TRNSCTN_ID, a.TRNSCTN_DATE,b.WraehouseName
FROM  SCPTnReturnToStore_M as a inner join SCPStWraehouseName as b on a.FromWarehouseId=b.WraehouseId
 where a.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or a.TRNSCTN_DATE  like '%'+@Trnsctn_ID+'%' or b.WraehouseName like '%'+@Trnsctn_ID+'%'
 order by a.TRNSCTN_DATE desc
END















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetReturnToSupplierForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish Tahir>
-- Create date: <Create 19-2-2018,,>
-- Description:	<Search fro,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToSupplierForSearch] 
@SearchID as varchar(50)
AS
BEGIN
	SELECT SCPTnReturnToSupplier_M.TRNSCTN_ID, SCPTnReturnToSupplier_M.TRNSCTN_DATE, 
	SCPStWraehouseName.WraehouseName,SCPTnReturnToSupplier_M.DatePassCode as GatePassCode,SCPStSupplier.SupplierShortName
	FROM SCPTnReturnToSupplier_M 
	INNER JOIN SCPStWraehouseName ON SCPTnReturnToSupplier_M.WraehouseId = SCPStWraehouseName.WraehouseId
	INNER JOIN SCPStSupplier ON SCPTnReturnToSupplier_M.SupplierId = SCPStSupplier.SupplierId
	where SCPTnReturnToSupplier_M.TRNSCTN_ID like '%'+@SearchID+'%'
	ORDER BY SCPTnReturnToSupplier_M.TRNSCTN_ID DESC
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetRouteOfAdministrationForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetRouteOfAdministrationForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.RouteOfAdministrationId,a.RouteOfAdministrationTitle,a.IsActive  from SCPStRouteOfAdministration as a
where a.RouteOfAdministrationTitle LIKE '%'+@Search+'%' 
order by a.RouteOfAdministrationId Desc
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetRouteOfAdministrationList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetRouteOfAdministrationList]
AS
BEGIN
	select RouteOfAdministrationId,RouteOfAdministrationTitle from SCPStRouteOfAdministration where IsActive=1 order by RouteOfAdministrationTitle
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSbCategoryListByCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSbCategoryListByCategory]
@CategoryId as int
AS
BEGIN
	 select SubCategoryId,SubCategoryName from SCPStSubCategory where IsActive=1 and CategoryId=@CategoryId order by SubCategoryName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSbClassByClassForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetSbClassByClassForSearch]
 
 @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.SubClassId,a.SubClassName,a.IsActive,b.ClassName  from SCPStSubClassification as a inner join SCPStClassification b on a.ClassId=b.ClassId
where a.ClassId=@ID and a.SubClassName LIKE '%'+@Search+'%' 
ORDER BY a.SubClassId DESC

END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSbClassList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSbClassList]
AS
BEGIN
	 select SubClassId,SubClassName from SCPStSubClassification where IsActive=1 order by SubClassName
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSbClassListByClass]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSbClassListByClass]
@ClassID as int
AS
BEGIN
	 select SubClassId,SubClassName from SCPStSubClassification where IsActive=1
	 and ClassId=@ClassID order by SubClassName
 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSCPStConsultantReferral]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPGetSCPStConsultantReferral]

AS
begin

;with a as (


select crp49.ConsultantId,crp20.ConsultantName Name,crp49.StandardAmount StandardAmount
,crp49.PerPrescripAmt
,Percentage  Percentage,crp49.AvgPatients
,round((((cast(crp49.AvgPatients as float)/100)*Percentage)),0) NoOfSCPTnInPatients

from SCPStConsultantReferral_M crp49
inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
where crp20.IsActive=1 and crp49.StandardAmount>0 

)
--select sum(rtrn) from a

select cast(row_number() over(order by Name) as varchar(max)) rn
,Name,AvgPatients,a.Percentage,a.NoOfSCPTnInPatients,a.PerPrescripAmt
,isnull(StandardAmount,0) StandardAmount From a
  end



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetShelfByRack]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfByRack] 
@ID as int
AS
BEGIN
	 select ShelfId,ShelfName from SCPStShelf where IsActive=1 and RackId=@ID order by ShelfName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetShelfByRackForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfByRackForSearch]
	
	@ShelfName as varchar(50),@ParentShlfId bigint
AS
BEGIN
	SELECT SCPStShelf.ShelfId, SCPStShelf.ShelfName, SCPStWraehouseName.WraehouseName, SCPStShelf.IsActive,SCPStRack.RackName
    FROM SCPStShelf  INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
	INNER JOIN SCPStWraehouseName ON SCPStRack.WraehouseId = SCPStWraehouseName.WraehouseId 
	WHERE SCPStShelf.ShelfName LIKE '%'+@ShelfName+'%' 
	and SCPStShelf.RackId=@ParentShlfId 
	ORDER BY SCPStShelf.ShelfId Desc
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetShelfForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfForSearch]
	
	@ShelfName as varchar(50)
AS
BEGIN
	SELECT SCPStShelf.ShelfId, SCPStShelf.ShelfName, SCPStRack.RackName , SCPStWraehouseName.WraehouseName,SCPStShelf.IsActive
    FROM SCPStShelf INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
	 INNER JOIN SCPStWraehouseName ON SCPStRack.WraehouseId = SCPStWraehouseName.WraehouseId 
	WHERE SCPStShelf.ShelfName LIKE '%'+@ShelfName+'%' OR SCPStShelf.ShelfId LIKE '%'+@ShelfName+'%'
	OR SCPStShelf.RackId LIKE '%'+@ShelfName+'%' OR SCPStWraehouseName.WraehouseName LIKE '%'+@ShelfName+'%'
	--SELECT SCPStShelf.ShelfId, SCPStShelf.ShelfName, SCPStWraehouseName.WraehouseName, SCPStShelf.IsActive
 --   FROM SCPStShelf INNER JOIN SCPStWraehouseName ON SCPStShelf.WraehouseId = SCPStWraehouseName.WraehouseId 
	--WHERE SCPStShelf.ShelfName LIKE '%'+@ShelfName+'%' OR SCPStShelf.ShelfId LIKE '%'+@ShelfName+'%'
	--OR SCPStWraehouseName.WraehouseName LIKE '%'+@ShelfName+'%'
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetShelfList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfList]
	
AS
BEGIN
	select ShelfId,ShelfName from SCPStShelf where IsActive=1 order by ShelfName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetShift]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetShift]
(
@SHIFT_ID AS INT)
AS
BEGIN
SELECT C.ShiftName,C.IsActive
FROM SCPStShift C
WHERE C.ShiftId=@SHIFT_ID
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetShiftForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetShiftForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.ShiftId,C.ShiftName,C.IsActive
FROM  SCPStShift C
WHERE C.ShiftName LIKE '%'+@name+ '%' 
ORDER BY C.ShiftName
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSignaDetailList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetSignaDetailList]
AS
BEGIN
SELECT SignaQuantity,SignaName,SignaId
FROM SCPStSigna C where IsActive=1
order by SignaName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSignaForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetSignaForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.SignaId,a.SignaName,a.SignaQuantity,a.SignaLabel,a.IsActive  from SCPStSigna as a
where a.SignaName LIKE '%'+@Search+'%' 
ORDER BY A.SignaId DESC 

END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSignaList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSignaList]
AS
BEGIN
  select SignaId,SignaName from SCPStSigna where IsActive=1 order by SignaName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSpeciality]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetSpeciality]
(
@SPEC AS INT)
AS
BEGIN
SELECT C.ConsultantSpecialityName,C.ConsultantFeildId,C.IsActive
FROM SCPStSpeciality C
WHERE C.ConsultantSpecialityId=@SPEC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSpecialityForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetSpecialityForSearch]
(
@name VARCHAR(50),
@CategoryId bigint
)
AS
BEGIN
SELECT C.ConsultantSpecialityId,C.ConsultantSpecialityName,C.IsActive,CS.CConsultantFeildName
FROM  SCPStSpeciality C,SCPStFeild CS
WHERE C.ConsultantSpecialityName LIKE '%'+@name+ '%' and c.ConsultantFeildId=@CategoryId  AND C.ConsultantFeildId=CS.ConsultantFeildId
ORDER BY C.ConsultantSpecialityId desc
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSpecialityList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSpecialityList]
AS
BEGIN
	select ConsultantSpecialityId,ConsultantSpecialityName from SCPStSpeciality
     where IsActive=1 order by ConsultantSpecialityName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStandardValue]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetStandardValue]
@FormCode VARCHAR(50),
@StandardId INT

AS BEGIN

	SELECT StandardFeildValue FROM SCPStStandardValue
	WHERE FormCode=@FormCode AND StandardFeildId=@StandardId

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStockConsumptionType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetStockConsumptionType]
@ItemConsumptionTypeID as int
AS
BEGIN

      SELECT ItemConsumptionIdTypeName,RangeFrom,RangeTo,IsActive FROM SCPStStockConsumptionType 
	  WHERE ItemConsumptionIdTypeId=@ItemConsumptionTypeID
	  ORDER BY ItemConsumptionIdTypeId desc
     
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStockConsumptionTypeForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetStockConsumptionTypeForSearch]
@ItemConsumptionType as varchar(50)
AS
BEGIN
      SELECT ItemConsumptionIdTypeId,ItemConsumptionIdTypeName,RangeFrom,RangeTo,IsActive FROM SCPStStockConsumptionType 
	  WHERE ItemConsumptionIdTypeName LIKE '%'+@ItemConsumptionType+'%' 
	  ORDER BY ItemConsumptionIdTypeId desc
END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStockItem]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockItem]
@WraehouseId as int
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M 
	INNER JOIN  SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
	ORDER BY ItemName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStockTakingForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockTakingForSearch]
@SearchID as varchar(50)
AS
BEGIN
	SELECT SCPTnStockTaking_M.TRNSCTN_ID, SCPTnStockTaking_M.TRNSCTN_DATE, SCPStWraehouseName.WraehouseName
FROM SCPTnStockTaking_M INNER JOIN SCPStWraehouseName ON SCPTnStockTaking_M.WraehouseId = SCPStWraehouseName.WraehouseId
where SCPTnStockTaking_M.TRNSCTN_ID like '%'+@SearchID+'%'
ORDER BY SCPTnStockTaking_M.TRNSCTN_ID DESC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStockTakingMaster]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetStockTakingMaster]
@paramTransectionId VARCHAR(50)
AS
BEGIN
		SELECT STM.TRNSCTN_ID AS TransectionId,
			   STM.CreatedDate AS CreatedOn,
			   WraehouseName.WraehouseName AS WraehouseNameName FROM [dbo].[SCPTnStockTaking_M] AS STM
		INNER JOIN [dbo].[SCPStWraehouseName] AS WraehouseName ON WraehouseName.WraehouseId = STM.WraehouseId
		WHERE STM.TRNSCTN_ID = @paramTransectionId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStrengthIdForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetStrengthIdForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.StrengthIdId,a.StrengthIdName,a.IsActive  from SCPStStrengthId as a
where a.StrengthIdName LIKE '%'+@Search+'%' 
ORDER BY StrengthIdId DESC 

END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetStrengthIdList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStrengthIdList]
AS
BEGIN
	select StrengthIdId,StrengthIdName from SCPStStrengthId where IsActive=1 order by StrengthIdName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSubCategoryForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetSubCategoryForSearch]
 
 @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.SubCategoryId,a.SubCategoryName,a.IsActive,b.CategoryName  from SCPStSubCategory as a 
inner join SCPStCategory b on a.CategoryId=b.CategoryId
where a.CategoryId=@ID and a.SubCategoryName LIKE '%'+@Search+'%' 
ORDER BY a.SubCategoryId Desc

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplier]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplier]
@SupplierId as int
AS
BEGIN
    SELECT SupplierCategoryId,ItemTypeId,'' SupplierShortName, SupplierLongName, FaxNo, STRegistrationNo,SaleTaxNo,AmountLimit,ContactNo1,
	ContactNo2,Address,DaysLimit,PaymentDayType,PaymentDate, PaymentDay ,PaymentDayType,OrderDayType,OrderDate,VendorChartId,
	OrderDay,OrderDayDetail,LeadTime,IsActive FROM SCPStSupplier where SupplierId=@SupplierId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplierCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierCategory]
@SupplierCatId as int
AS
BEGIN
      select SupplierCategoryName,IsActive from SCPStSupplierCategory where SupplierCategoryId=@SupplierCatId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplierCategoryForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierCategoryForSearch]
	
	@SupplierCatName as varchar(50)
AS
BEGIN
	 SELECT SupplierCategoryId,SupplierCategoryName,IsActive
     FROM SCPStSupplierCategory C WHERE SupplierCategoryName LIKE '%'+@SupplierCatName+'%' 
	 ORDER BY SupplierCategoryId Desc
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplierCategoryList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierCategoryList]
AS
BEGIN
	select SupplierCategoryId,SupplierCategoryName from SCPStSupplierCategory
     where IsActive=1 order by SupplierCategoryName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplierForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierForSearch]
@CategoryId as int,
@VNDR_S_NAME as varchar(50)
AS
BEGIN
	SELECT  C.SupplierId, SCPStSupplierCategory.SupplierCategoryName,SCPStItemType.ItemTypeName ,C.SupplierShortName, C.SupplierLongName, C.FaxNo, C.STRegistrationNo, C.ContactNo1,
    C.ContactNo2, C.Address, C.DaysLimit
    FROM  SCPStSupplier C INNER JOIN SCPStSupplierCategory ON SCPStSupplierCategory.SupplierCategoryId = C.SupplierCategoryId
	INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = C.ItemTypeId
    WHERE C.SupplierCategoryId=@CategoryId and (C.SupplierShortName LIKE '%'+@VNDR_S_NAME+'%' OR
	C.SupplierLongName LIKE '%'+@VNDR_S_NAME+'%')
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplierList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierList]
AS
BEGIN
	 select a.SupplierId,a.SupplierLongName from SCPStSupplier as a
     where a.IsActive=1 order by a.SupplierLongName
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSupplierListByType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierListByType]
@ItemTypeId AS INT
AS
BEGIN
	SELECT SupplierId,SupplierLongName FROM SCPStSupplier WHERE ItemTypeId=@ItemTypeId AND IsActive=1 order by SupplierLongName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetTotalDemand]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetTotalDemand] 
AS
BEGIN
		  DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
		  --SELECT @REPORT_DATE
  
   				select isnull((select count(*) from SCPTnDemand_M where IsActive =1 
				and DemandType='M' and	CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) 
				AND CAST(@REPORT_DATE AS date)),0) AutoDmnd,count(*) TotalDmnd from SCPTnDemand_M where IsActive =1 and
				CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetTotalItemsCount]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[Sp_SCPGetTotalItemsCount] 

AS
BEGIN
	
	  select Count(ItemCode) from SCPStItem_M
	  where IsActive = 1

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserBatchNo]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserBatchNo]
@userId as int	
AS
BEGIN
	select isnull(BatchNo,'') from SCPTnBatchNo_M where USR_ID=@userId and IsActive=1 and BatchNoCloseTime is NULL
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserBatchNoDetail]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserBatchNoDetail]
@userId as int	
AS
BEGIN
	select BatchNo,BatchNoStartTime,OpeningClose,TerminalName from SCPTnBatchNo_M where USR_ID=@userId and IsActive=1 and BatchNoCloseTime is NULL
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserDeligation]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetUserDeligation]
@UsrId as int	
AS
BEGIN
	SET NOCOUNT ON;

   SELECT * FROM SCPStDeligation WHERE SCPStDeligation.UserId = @UsrId
AND GETDATE() < SCPStDeligation.ToDate
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserDesignation]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserDesignation]
@DocumentType AS VARCHAR(50)
AS
BEGIN
	 SELECT Designation FROM SCPStApproval WHERE DocumentType=@DocumentType
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserGroup]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserGroup]
@User_Grp_Id as int
AS
BEGIN
	select UserGroup,IsActive from SCPStUserGroup_M where UserGroupId=@User_Grp_Id
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserGroupForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserGroupForSearch] 
@Search as varchar(50)
AS
BEGIN
	select UserGroupId,UserGroup from SCPStUserGroup_M
    where SCPStUserGroup_M.IsActive=1 and UserGroupId like '%'+@Search+'%' OR UserGroup like '%'+@Search+'%'
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetUserGroupList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserGroupList]
AS
BEGIN
	 select UserGroupId,UserGroup from SCPStUserGroup_M where IsActive=1 order by UserGroup
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetVendorChart]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE PROC [dbo].[Sp_SCPGetVendorChart]
   AS BEGIN
  SELECT VendorChartId,VendorChart FROM SCPStVendorChart WHERE IsActive=1
  END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseName]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetWraehouseName]
(
@FormCode AS INT)
AS
BEGIN
SELECT C.WraehouseName,C.IsActive,ItemTypeId
FROM SCPStWraehouseName C
WHERE C.WraehouseId=@FormCode
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseNameByType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameByType]
@ItemTypeId as int
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouseName where IsActive=1 AND ItemTypeId=@ItemTypeId  order by WraehouseId
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseNameByTypeForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPGetWraehouseNameByTypeForSearch]
(
@name VARCHAR(50),
@Type_id bigint
)
AS
BEGIN
SELECT SCPStWraehouseName.WraehouseId, SCPStWraehouseName.WraehouseName, SCPStItemType.ItemTypeName, SCPStWraehouseName.IsActive
FROM SCPStWraehouseName INNER JOIN SCPStItemType ON SCPStWraehouseName.ItemTypeId = SCPStItemType.ItemTypeId

WHERE WraehouseName LIKE '%'+@name+ '%'  and SCPStWraehouseName.ItemTypeId=@Type_id  AND SCPStWraehouseName.ItemTypeId=SCPStItemType.ItemTypeId
ORDER BY SCPStWraehouseName.WraehouseName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseNameForPos]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameForPos]
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouseName where IsActive=1 and ItemTypeId=2 order by WraehouseId
 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseNameForPurchase]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameForPurchase]
@ItemTypeId as int
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouseName where IsActive=1 AND IsAllow=1
    AND ItemTypeId=@ItemTypeId  order by WraehouseId
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseNameForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPGetWraehouseNameForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT SCPStWraehouseName.WraehouseId, SCPStWraehouseName.WraehouseName, SCPStItemType.ItemTypeName, SCPStWraehouseName.IsActive
FROM SCPStWraehouseName INNER JOIN SCPStItemType ON SCPStWraehouseName.ItemTypeId = SCPStItemType.ItemTypeId

WHERE WraehouseName LIKE '%'+@name+ '%' 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWraehouseNameList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameList]
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouseName where IsActive=1  order by WraehouseId
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetWrongEntriesStock]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWrongEntriesStock]
@WraehouseName INT
AS
BEGIN

select 0.0 AS DEAD_STOCK

--SELECT CASE WHEN @WraehouseName=3 THEN phm ELSE mss END AS DEAD_STOCK FROM
--(
      --SELECT SUM(MSS*CostPrice) AS mss,SUM(PHM*CostPrice) AS phm from
	-- (
	 --  SELECT TMPP.ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel,ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	 --  WHERE WraehouseId=3 AND ItemCode=TMPP.ItemCode),0) AS PHM, ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	 --  WHERE WraehouseId=10 AND ItemCode=TMPP.ItemCode),0) as MSS,CostPrice FROM
	 --   (
		--	SELECT ItemCode,ItemName,0 AS pos_MinLevel,0 AS pos_MaxLevel,SUM(MinLevel) AS MSS_MinLevel,
		--	SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate!='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode,ItemName,CostPrice --HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--    )TMPP GROUP BY TMPP.ItemCode,ItemName,CostPrice,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel
		--	UNION ALL
	 --  SELECT TMPP.ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MIN,MSS_MAX,ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	 --  WHERE WraehouseId=3 AND ItemCode=TMPP.ItemCode),0) as PHM,ISNULL((SELECT sum(CurrentStock) 
	 --  FROM SCPTnStock_M WHERE WraehouseId=10 AND ItemCode=TMPP.ItemCode),0) AS MSS,CostPrice FROM
	 --   (
		--	SELECT ItemCode,ItemName,SUM(MinLevel) AS pos_MinLevel,SUM(MaxLevel) AS pos_MaxLevel,0 AS MSS_MIN,0 AS MSS_MAX,CostPrice FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.PARENT_TRNSCTNID = SCPStParLevelAssignment_M.TRNSCTN_ID AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--	    AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate!='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode,ItemName,CostPrice --HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)TMPP GROUP BY TMPP.ItemCode,ItemName,CostPrice,pos_MinLevel,pos_MaxLevel,MSS_MIN,MSS_MAX
	--)TMPPP
--)TMPPPP
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDetailForDiscard]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[Sp_SCPItemDetailForDiscard] 
(
@ITEM_CODE varchar(50),
@BatchNo varchar(50),
@Wid int
)
AS
BEGIN

SELECT ISNULL(I.CurrentStock,0) as CurSock,k.ItemRate,k.ExpiryDate as DT FROM SCPTnStock_M I
inner join SCPTnGoodReceiptNote_D as k on k.BatchNo=I.BatchNo and I.ItemCode=k.ItemCode WHERE I.WraehouseId=@Wid 
and I.ItemCode=@ITEM_CODE and I.BatchNo=@BatchNo and I.CurrentStock>0  

END









GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemTradePriceList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPItemTradePriceList]
@ItemCode AS VARCHAR(50)
AS
BEGIN
    SELECT ItemCode,TradePrice FROM SCPStRate WHERE 
    SCPStRate.ItemRateId=(select isnull(Max(CRP.ItemRateId),0) from SCPStRate CRP where CONVERT(date, getdate()) between 
	CRP.FromDate and CRP.ToDate and CRP.ItemCode=SCPStRate.ItemCode)
	AND SCPStRate.ItemCode=@ItemCode
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPQualificationForSearch]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPQualificationForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT c.QualificationName ,c.QualificationId,c.IsActive
FROM  SCPStQualification c
WHERE c.QualificationName LIKE '%'+@name+ '%' 
ORDER BY c.QualificationName
END  


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptAdjustment_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptAdjustment_M]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT SCPStWraehouseName.WraehouseName,CONVERT(VARCHAR(10), SCPTnAdjustment_M.TRNSCTN_DATE, 105) AS TRNSCTN_DATE,SCPStUser_M.UserName,
    (CONVERT(VARCHAR(10), SCPTnAdjustment_M.CreatedDate, 105)+' '+ CONVERT(VARCHAR(5),SCPTnAdjustment_M.CreatedDate,108)) AS CRTD_DATE FROM SCPTnAdjustment_M
    INNER JOIN SCPStWraehouseName ON SCPTnAdjustment_M.WraehouseId = SCPStWraehouseName.WraehouseId
	INNER JOIN SCPStUser_M ON SCPStUser_M.USR_ID = SCPTnAdjustment_M.CRTD_BY WHERE TRNSCTN_ID=@TRNSCTN_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptBatchNoOpeningClosing]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptBatchNoOpeningClosing]
@BatchNo AS VARCHAR(50)
AS
BEGIN

	select (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108))
    AS OPNG_TM,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL 
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_DTL.IsActive=1
	AND SL_MSTR.BatchNo=@BatchNo),0) AS CSH_SL,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) CSH_SL FROM SCPTnSale_D SL_DTL	
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_DTL.IsActive=1
	AND SL_MSTR.BatchNo=@BatchNo),0) AS CRDT_SL,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND RTN_DTL.IsActive=1
	AND RTN_MSTR.BatchNo=@BatchNo),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2 AND RTN_DTL.IsActive=1 AND 
	RTN_MSTR.BatchNo=@BatchNo),0) AS CRDT_RTN,
	(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM from SCPTnBatchNo_M
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID 
	WHERE SCPTnBatchNo_M.BatchNo=@BatchNo AND SCPTnBatchNo_M.IsActive=1
	GROUP BY SCPTnBatchNo_M.BatchNo,BatchNoStartTime, BatchNoCloseTime,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptBatchNoWisePtCategoyWiseRevenue]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPRptBatchNoWisePtCategoyWiseRevenue]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)

AS BEGIN

SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,SUM(PT_COUNT) AS PT_COUNT,
	  SUM(AMOUNT)-SUM(RefundAmount) AS AMOUNT  FROM
(
	  SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,COUNT(TRANS_ID) AS PT_COUNT,
	  SUM(AMT) AS AMOUNT,0 AS RefundAmount FROM
	(
		SELECT CAST(BB.BatchNoStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
		PHM.TRANS_ID,SUM(ROUND((Quantity*PRICE),0)) AS AMT FROM SCPTnSale_M PHM
		INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
		INNER JOIN SCPStPatientCategory CAT ON PatientCategoryId = PatientCategoryId
		INNER JOIN SCPStPatientSubCategory SB ON SB.PatientCategoryId = CAT.PatientCategoryId AND SB.PatientSubCategoryId = PHM.PatientSubCategoryId
		INNER JOIN SCPTnSale_D PHD ON PARNT_TRANS_ID = PHM.TRANS_ID
		INNER JOIN SCPStUser_M SS ON PHM.CRTD_BY = SS.USR_ID
		WHERE CAST(BB.BatchNoStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND 
		CAST(CONVERT(date,@ToDate,103) as date)
		GROUP BY CAST(BB.BatchNoStartTime AS DATE),PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
		PHM.TRANS_ID
	)TMP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
	UNION ALL
	SELECT CAST(BB.BatchNoStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PatientCategoryName AS SCPTnInPatient_Category,
	PatientSubCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientSubCategory SB ON SB.PatientCategoryId = PT_CT.PatientCategoryId AND SB.PatientSubCategoryId = PMM.PatientSubCategoryId
	INNER JOIN SCPStUser_M SS ON PHM.CRTD_BY = SS.USR_ID
	WHERE CAST(BB.BatchNoStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	GROUP BY CAST(BB.BatchNoStartTime AS DATE),PHM.BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
	UNION ALL
	SELECT T_DATE,BatchNo,UserName,SCPTnInPatient_Category,PatientSubCategoryName,0 AS Prescription,0 AS SaleAmount,
	  SUM(ROUND(RefundAmount,0)) AS RefundAmount FROM
	(
		SELECT DISTINCT T_DATE,BatchNo,UserName,PatinetIp,SCPTnInPatient_Category,PatientSubCategoryName,ItemCode,RefundAmount FROM
		(
			SELECT CAST(BB.BatchNoStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PHM.PatinetIp,
			PatientCategoryName AS SCPTnInPatient_Category,CASE WHEN PatientTypeId=1 AND PHD.PaymentTermId=2 
			THEN 'OT' ELSE 'Per' END AS PatientSubCategoryName,PHD.ItemCode,ReturnAmount AS RefundAmount
			FROM SCPTnSaleRefund_M PHM 
			INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
			INNER JOIN SCPTnSale_M PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0' 
			INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
			INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID  
			INNER JOIN SCPStUser_M SS ON PHM.CRTD_BY = SS.USR_ID
			WHERE CAST(BB.BatchNoStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
			AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
		)TMP
	)TMPP GROUP BY T_DATE,BatchNo,UserName,SCPTnInPatient_Category,PatientSubCategoryName
)TMPP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
ORDER BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
	


--SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,COUNT(TRANS_ID) AS PT_COUNT,SUM(AMT) AS AMOUNT FROM
--(
--	SELECT CAST(BB.BatchNoStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
--	PHM.TRANS_ID,SUM(ROUND((Quantity*PRICE),0)) AS AMT FROM SCPTnSale_M PHM
--	INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
--	INNER JOIN SCPStPatientCategory CAT ON PatientCategoryId = PatientCategoryId
--	INNER JOIN SCPStPatientSubCategory SB ON SB.PatientCategoryId = CAT.PatientCategoryId AND SB.PatientSubCategoryId = PHM.PatientSubCategoryId
--	INNER JOIN SCPTnSale_D PHD ON PARNT_TRANS_ID = PHM.TRANS_ID
--	INNER JOIN SCPStUser_M SS ON PHM.CRTD_BY = SS.USR_ID
--	WHERE CAST(BB.BatchNoStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
--	AND CAST(CONVERT(date,@ToDate,103) as date)
--	GROUP BY CAST(BB.BatchNoStartTime AS DATE),PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
--	PHM.TRANS_ID
--)TMP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
--ORDER BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptCareofSaleSummary]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptCareofSaleSummary]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

  
SELECT TRANS_DT,CareOf, PTName,PatientCategoryName, sum(TotalSale), CareOf , SUM(RTRN_AMOUNT), CASE 
WHEN CareOffCode = 1 THEN (SELECT TOP 1  EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON X.CareOff = EMP.EmployeeCode)
WHEN CareOffCode = 2 THEN (SELECT TOP 1  CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnSale_M ON X.CareOff = CONS.ConsultantId)
WHEN CareOffCode = 3 THEN (SELECT  TOP 1  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON X.CareOff = PART.PartnerId)
END AS CAREOF_NM  FROM (

SELECT CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) as TRANS_DT ,SUM(ROUND(Quantity*ItemRate,0)) as TotalSale,CareOffCode,
(CASE WHEN CareOffCode = 1 THEN 'Employee' WHEN CareOffCode=2 THEN 'Consultant' WHEN CareOffCode = 3 THEN 'Partner' END) AS CareOf
	,CareOff
,  (NamePrefix+'. '+FirstName+' '+LastName) as [PTName], PatientCategoryName	 ,
	(SELECT isnull(SUM(PHD.ReturnAmount),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.SaleRefundId = PHM.SaleRefundId 
	 AND PHM.SaleId = SCPTnSale_M.SaleId AND CAST(PHM.SaleRefundDate as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) and PHM.IsActive=1) AS RTRN_AMOUNT   
			from SCPTnSale_M 
			INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
			INNER JOIN SCPStPatientCategory ON SCPStPatientCategory.PatientCategoryId = SCPTnSale_M.PatientCategoryId
			where PatientTypeId= 1 AND SCPTnSale_M.SaleId!='0' AND SCPTnSale_M.PatientIp='0' and SCPTnSale_M.IsActive=1
			GROUP BY  SCPTnSale_M.SaleId ,
			CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) ,CareOffCode, CareOff, NamePrefix, FirstName, LastName, PatientCategoryName
)X
GROUP BY TRANS_DT,CareOf, PTName,PatientCategoryName,CareOf, CareOff, CareOffCode

  UNION ALL 
SELECT TRANS_DT,CareOf, PTName,PatientCategoryName, sum(TotalSale), CareOf , SUM(RTRN_AMOUNT), CASE 
WHEN CareOffCode = 1 THEN (SELECT TOP 1  EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON X.CareOff = EMP.EmployeeCode)
WHEN CareOffCode = 2 THEN (SELECT TOP 1  CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnSale_M ON X.CareOff = CONS.ConsultantId)
WHEN CareOffCode = 3 THEN (SELECT  TOP 1  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON X.CareOff = PART.PartnerId)
END AS CAREOF_NM  FROM (

SELECT CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) as TRANS_DT ,SUM(ROUND(Quantity*ItemRate,0))  as TotalSale,CareOffCode,
(CASE WHEN CareOffCode = 1 THEN 'Employee' WHEN CareOffCode=2 THEN 'Consultant' WHEN CareOffCode = 3 THEN 'Partner' END) AS CareOf
	,CareOff
,  (NamePrefix+'. '+FirstName+' '+LastName) as [PTName], PatientCategoryName	 ,
	(SELECT isnull(SUM(PHD.ReturnAmount),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.SaleRefundId = PHM.SaleRefundId 
	 AND PHM.PatinetIp = SCPTnSale_M.PatientIp AND CAST(PHM.SaleRefundDate as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) and PHM.IsActive=1) AS RTRN_AMOUNT   
			from SCPTnSale_M 
			INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
			INNER JOIN SCPStPatientCategory ON SCPStPatientCategory.PatientCategoryId = SCPTnSale_M.PatientCategoryId
			where PatientTypeId= 1  AND SCPTnSale_M.PatientIp !='0' and SCPTnSale_M.IsActive=1
			GROUP BY  SCPTnSale_M.PatientIp ,
			CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) ,CareOffCode, CareOff, NamePrefix, FirstName, LastName, PatientCategoryName
)X 
GROUP BY TRANS_DT,CareOf, PTName,PatientCategoryName,CareOf, CareOff, CareOffCode
--SELECT sum(ReturnAmount) FROM SCPTnSale_M
--INNER JOIN SCPTnSale_D ON SCPTnSale_M.TRANS_ID = SCPTnSale_D.PARNT_TRANS_ID
--INNER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.PatinetIp = SCPTnSale_M.PatientIp
--INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
-- WHERE CAST(SCPTnSaleRefund_M.TRNSCTN_DATE as date)= CAST(CONVERT(date,@FromDate,103) as date) AND PatientCategoryId = 1
-- select sum(ReturnAmount) from SCPTnSaleRefund_M 
-- INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
-- WHERE CAST(SCPTnSaleRefund_M.TRNSCTN_DATE as date) = CAST(CONVERT(date,@ToDate,103) as date)
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptConsultantWiseInventory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPRptConsultantWiseInventory]

AS BEGIN

	SELECT MemberName,0 NoOfPts,COUNT(Items) Items,SUM(POS_MEAN_VAL+MSS_MEAN_VAL) Invntry,1.2 Stndrd,
	CASE WHEN SUM(POS_MEAN_VAL+MSS_MEAN_VAL)=0 AND SUM(Sales)!=0 THEN 0 WHEN SUM(Sales)=0 THEN 1 
	ELSE (SUM(Sales))/SUM(POS_MEAN_VAL+MSS_MEAN_VAL) END AS SalesRatio FROM
	(
		SELECT MemberName,Items,Sales,(CAST(ROUND(CAST(SUM(MinLevel)+SUM(MaxLevel) AS FLOAT)/2,0) AS INT)
		*CostPrice) AS POS_MEAN_VAL,(CAST(ROUND(CAST(SUM(MSS_MinLevel)+SUM(MSS_MaxLevel) AS FLOAT)/2,0) AS INT)
		*CostPrice) AS MSS_MEAN_VAL FROM
		(
			SELECT CASE WHEN RC.ConsultantId IS NULL THEN RC.RecommendedMemberName ELSE CON.ConsultantName END AS MemberName,
			ISNULL(OP.PatientCount,0) NoOfPts,ISNULL(CASE WHEN SCPStParLevelAssignment_D.ParLevelId=14 THEN SCPStParLevelAssignment_D.NewLevel END,0) AS MinLevel,
			ISNULL(CASE WHEN SCPStParLevelAssignment_D.ParLevelId=16 THEN SCPStParLevelAssignment_D.NewLevel END,0) AS MaxLevel,CostPrice,CC.ItemCode AS Items,
			ISNULL((SELECT SUM(ROUND(Quantity*ItemRate,0)) FROM SCPTnSale_D PHD WHERE PHD.ItemCode=CC.ItemCode AND 
			CAST(PHD.CreatedDate AS DATE) BETWEEN DATEADD(DAY,-30, GETDATE()) AND GETDATE()),0) Sales,
			ISNULL(CASE WHEN ccd.ParLevelId=14 THEN ccd.NewLevel END,0) AS MSS_MinLevel,
			ISNULL(CASE WHEN ccd.ParLevelId=16 THEN ccd.NewLevel END,0) AS MSS_MaxLevel FROM SCPStItem_M CC
			INNER JOIN SCPStItem_M_RecommendationApproval REC ON REC.ItemCode = CC.ItemCode
			INNER JOIN SCPStRecommendedBy RC ON RC.RecommendedMemberId = REC.RecommendedMemberId
			INNER JOIN SCPStConsultant CON ON CON.ConsultantId = RC.ConsultantId
			LEFT OUTER JOIN SCPTnOPDPatient OP ON OP.ConsultantId = CON.ConsultantId 
			AND CAST(OP.DataDate AS DATE) = CAST(DATEADD(D,-1,GETDATE()) AS DATE)
			INNER JOIN SCPStParLevelAssignment_M ON CC.ItemCode = SCPStParLevelAssignment_M.ItemCode
			INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN(14,16)	AND 
			SCPStParLevelAssignment_M.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=3)
			INNER JOIN SCPStParLevelAssignment_M ccm ON CC.ItemCode = ccm.ItemCode
			INNER JOIN SCPStParLevelAssignment_D ccd ON ccd.ParLevelAssignmentId = ccm.ParLevelAssignmentId AND ccd.ParLevelId IN(14,16)	AND 
			ccm.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=10)
			INNER JOIN SCPStRate ON CC.ItemCode = SCPStRate.ItemCode
			AND SCPStRate.ItemRateId=(SELECT ISNULL(MAX(ItemRateId),0) FROM SCPStRate 
			WHERE CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=CC.ItemCode)
		)TMP#0 GROUP BY  MemberName,Items,Sales,CostPrice 
	)TMP#1 GROUP BY MemberName

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptCurrentYearMonthlyPurchase]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptCurrentYearMonthlyPurchase]
AS
BEGIN
   SELECT SubString(Convert(Varchar(Max), CreatedDate,0), 1, 3) + '/' + Cast(Year(CreatedDate) As Varchar(Max)) as Year_Month,
       right(convert(varchar, CreatedDate, 103), 7) as CreatedDate,
       SUM(NetAmount) AS TotalPuchase FROM SCPTnGoodReceiptNote_M
	   WHERE WraehouseId IN(SELECT WraehouseId FROM SCPStWraehouseName WHERE ItemTypeId=2 AND IsActive=1) 
	  -- AND CreatedDate BETWEEN DATEADD(YEAR,-1,GETDATE()) AND GETDATE() 
	   AND Year(CreatedDate) = Year(GETDATE())AND IsActive=1
   GROUP BY right(convert(varchar, CreatedDate, 103), 7),SubString(Convert(Varchar(Max), CreatedDate,0), 1, 3) + '/' + Cast(Year(CreatedDate) As Varchar(Max))
   ORDER BY right(convert(varchar, CreatedDate, 103), 7)  
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDailyPharmacySale]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDailyPharmacySale]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)
AS
BEGIN

 -- SELECT TRANS_DT,BatchNo,UserName,OPNG_TM,CSH_SL,CRDT_SL,CSH_RTN,CRDT_RTN,(CSH_SL-CSH_RTN) AS CSH_NET_SL,
 -- (CRDT_SL-CRDT_RTN) AS CRDT_NET_SL,CLSNG_TM FROM
 -- (
 --   SELECT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) AS OPNG_TM,
	--ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
	--CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CSH_SL,
	--ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_SL,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND	CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) CSH_RTN,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
	--AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_RTN,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM 
	--FROM SCPTnSale_M INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
 --   INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID INNER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID
	--LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
	--LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	--WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
	--GROUP BY CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)),
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108))
 -- )TMP

 --  SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
 -- SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
 --(SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM 
 -- FROM
 -- (
 --   SELECT SCPTnSale_M.TRANS_DT AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) AS OPNG_TM,
	--ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
	--SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CSH_SL, ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	
	--INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND
	-- SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CRDT_SL,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND	RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
	--INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND 
	--RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo	AND RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) AS CRDT_RTN,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM 
	--FROM SCPTnSale_M INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID 
	--INNER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
	--LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	--WHERE CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	--GROUP BY SCPTnSale_M.TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)),
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108))
 -- )TMP GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,UserName,OPNG_TM,CLSNG_TM


 --- COMMENTED ON 27-10-2018
--    SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
--  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
-- (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM 
--  FROM
--  (
--select   SCPTnBatchNo_D.BatchNo, (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+
-- CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) AS OPNG_TM
--, SCPStUser_M.UserName,SCPTnSale_M.TRANS_DT,
--	ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
--	SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CSH_SL, 
--	ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	
--	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND
--	 SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CRDT_SL,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
--	AND	RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) CSH_RTN,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
--	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND 
--	RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo	AND RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) AS CRDT_RTN,
--		(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM 
	
--	  from SCPTnBatchNo_M
--	INNER JOIN SCPTnBatchNo_D ON SCPTnBatchNo_M.BatchNo = SCPTnBatchNo_D.BatchNo 
--	LEFT OUTER JOIN SCPTnSale_M ON SCPTnBatchNo_D.BatchNo = SCPTnSale_M.BatchNo AND 
--	SCPTnSale_M.CRTD_BY = SCPTnBatchNo_D.USR_ID
--	INNER JOIN SCPStUser_M ON SCPTnBatchNo_D.USR_ID = SCPStUser_M.USR_ID 
--	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID 
--	LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
--	LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
--	WHERE CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date)
--	AND CAST(CONVERT(date,@ToDate,103) as date)
--	GROUP BY SCPTnBatchNo_D.BatchNo,BatchNoStartTime, BatchNoCloseTime, 
--	SCPStUser_M.UserName, SCPTnSale_M.BatchNo, SCPTnSale_M.TRANS_DT
	
--	)tmp GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,OPNG_TM,CLSNG_TM, UserName ORDER BY TRANS_DT


--    SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
--  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
-- (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM 
--  FROM
--  (
--select   SCPTnBatchNo_D.BatchNo, (CONVERT(VARCHAR(10), SCPTnBatchNo_D.StartTime, 105)+' '+
-- CONVERT(VARCHAR(5), SCPTnBatchNo_D.StartTime,108)) AS OPNG_TM
--, SCPStUser_M.UserName,SCPTnSale_M.TRANS_DT,
--	ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
--	SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CSH_SL, 
--	ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	
--	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND
--	 SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CRDT_SL,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
--	AND	RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) CSH_RTN,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
--	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND 
--	RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo	AND RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) AS CRDT_RTN,
--		(CONVERT(VARCHAR(10), SCPTnBatchNo_D.CloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_D.CloseTime,108)) AS CLSNG_TM 
	
--	  from SCPTnBatchNo_M
--	INNER JOIN SCPTnBatchNo_D ON SCPTnBatchNo_M.BatchNo = SCPTnBatchNo_D.BatchNo 
--	LEFT OUTER JOIN SCPTnSale_M ON SCPTnBatchNo_D.BatchNo = SCPTnSale_M.BatchNo AND 
--	SCPTnSale_M.CRTD_BY = SCPTnBatchNo_D.USR_ID
--	INNER JOIN SCPStUser_M ON SCPTnBatchNo_D.USR_ID = SCPStUser_M.USR_ID 
--	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID 
--	LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
--	LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
--	WHERE CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,'15-09-2018',103) as date)
--	AND CAST(CONVERT(date,'20-09-2018',103) as date)
--	GROUP BY SCPTnBatchNo_D.BatchNo, SCPTnBatchNo_D.StartTime, SCPTnBatchNo_D.CloseTime,
--	SCPStUser_M.UserName, SCPTnSale_M.BatchNo, SCPTnSale_M.TRANS_DT
	
--	)tmp GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,OPNG_TM,CLSNG_TM, UserName

  SELECT CONVERT(VARCHAR(10),CreatedDate, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
  (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM FROM
   (
    select SCPTnBatchNo_M.BatchNo, (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108))
    AS OPNG_TM,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL 
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 and SL_MSTR.IsActive=1 
	AND SL_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and SL_MSTR.IsActive=1),0) AS CSH_SL,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL	
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2  and SL_MSTR.IsActive=1 
	AND SL_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and SL_MSTR.IsActive=1),0) AS CRDT_SL,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 and RTN_MSTR.IsActive=1 
	AND RTN_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and RTN_MSTR.IsActive=1),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2 and RTN_MSTR.IsActive=1 AND 
	RTN_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and RTN_MSTR.IsActive=1),0) AS CRDT_RTN,
	(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM from SCPTnBatchNo_M
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID 
	WHERE CAST(SCPTnBatchNo_M.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	GROUP BY SCPTnBatchNo_M.BatchNo,BatchNoStartTime, BatchNoCloseTime,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate
	)tmp GROUP BY CONVERT(VARCHAR(10),CreatedDate, 105),BatchNo,OPNG_TM,CLSNG_TM,UserName 

 
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscardPODetail]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDiscardPODetail]
@PurchaseOrderNo as VARCHAR(50)
AS
BEGIN
	SELECT DISTINCT SCPTnPurchaseOrder_D.TRNSCTN_ID,SCPTnPurchaseOrder_D.ItemCode,ItemName,SCPTnPurchaseOrder_D.OrderQty,SCPTnPurchaseOrder_D.PendingQty,SCPTnPurchaseOrder_D.DiscardQty,
    CASE WHEN ReasonId IS NULL THEN DiscardReasonId ELSE ReasonId END AS ReasonId FROM SCPTnPurchaseOrder_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode
    INNER JOIN SCPTnPODiscard_M ON SCPTnPODiscard_M.PurchaseOrderNo = SCPTnPurchaseOrder_D.PARENT_TRNSCTN_ID
    INNER JOIN SCPTnPODiscard_D ON SCPTnPODiscard_M.TRANSCTN_ID = SCPTnPODiscard_D.PARENT_TRNSCTN_ID AND SCPTnPurchaseOrder_D.ItemCode=SCPTnPODiscard_D.ItemCode
    LEFT OUTER JOIN SCPStReasonId ON SCPStReasonId.ReasonId = SCPTnPODiscard_D.DiscardReasonIdId
    WHERE SCPTnPurchaseOrder_D.PARENT_TRNSCTN_ID=@PurchaseOrderNo AND SCPTnPurchaseOrder_D.DiscardQty>0
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscardPOMaster]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDiscardPOMaster]
@PurchaseOrderNo as VARCHAR(50)
AS
BEGIN
	SELECT TRNSCTN_ID,TRNSCTN_DATE,ItemTypeName FROM SCPTnPurchaseOrder_M
    INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId = SCPTnPurchaseOrder_M.WarehouseId
    INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = SCPStWraehouseName.ItemTypeId WHERE TRNSCTN_ID=@PurchaseOrderNo
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptGoodReturn_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptGoodReturn_M]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT TRANSCTN_DT,DepartmentName,WraehouseName FROM SCPTnGoodReturn_M
	INNER JOIN SCPStDepartment ON SCPStDepartment.DepartmentId = SCPTnGoodReturn_M.DepartmentId
	INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId=SCPTnGoodReturn_M.WarehouseId
	WHERE TRANSCTN_ID=@TRNSCTN_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptHospitalFormulary_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Tabish Tahir>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptHospitalFormulary_D] --@cls = 47
@Cls as int  ,
@SubCls as int,
@Cat as int,
@SubCat as int
AS

BEGIN
	SET NOCOUNT ON;
 IF(@Cls != 0 AND @SubCls = 0 AND @Cat = 0 AND @SubCat = 0)
	BEGIN
		SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode, 
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
		INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND a.ClassId =@Cls AND a.IsActive=1
	
END
ELSE IF (@Cls != 0 AND @SubCls != 0 AND @Cat = 0 AND @SubCat = 0)
BEGIN 
SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode,
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
	   INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND A.SubClassId= @SubCls AND a.IsActive=1
END
ELSE IF (@Cls != 0 AND @SubCls! = 0 AND @Cat != 0 AND @SubCat = 0)
BEGIN 
SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode, 
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
		INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND a.CategoryId = @Cat AND a.IsActive=1
END

ELSE IF (@Cls != 0 AND @SubCls != 0 AND @Cat != 0 AND @SubCat != 0)
BEGIN 
SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode, 
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
		INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND a.SubCategoryId  = @SubCat AND a.IsActive=1 
END
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptHospitalFormulary_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptHospitalFormulary_M]
AS
BEGIN
		SELECT FormularyName,COUNT(SCPStItem_M.ItemCode) AS TTL_ITEM,COUNT(SCPTnSale_D.ItemCode) AS SL_ITEM,
	CASE WHEN SCPStFormulary.FormularyId=40 THEN '80 %' WHEN SCPStFormulary.FormularyId=41 THEN '100 %'
	WHEN SCPStFormulary.FormularyId=42 THEN '60 %' ELSE '' END AS STNDRD  FROM SCPStFormulary 
	LEFT OUTER JOIN SCPStItem_M ON SCPStItem_M.FormularyId = SCPStFormulary.FormularyId
	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
	WHERE SCPStItem_M.IsActive=1
	GROUP BY SCPStFormulary.FormularyId,FormularyName
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptItemReturntoSupplier_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptItemReturntoSupplier_M]
@paramTransectionId AS INT
AS
BEGIN
		SELECT RSM.TRNSCTN_ID AS TransectionId,
			   RSM.DatePassCode AS GatePassCode,
			   WraehouseNames.WraehouseName AS WraehouseNameName,
			   Supplier.SupplierLongName AS SupplieName
			   FROM [dbo].[SCPTnReturnToSupplier_M] AS RSM
		INNER JOIN [dbo].[SCPStSupplier] AS Supplier ON Supplier.SupplierId = RSM.SupplierId
		INNER JOIN [dbo].[SCPStWraehouseName] AS WraehouseNames ON WraehouseNames.WraehouseId = RSM.WraehouseId
		WHERE RSM.TRNSCTN_ID = @paramTransectionId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptItemWiseRate]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptItemWiseRate]

@SupId as int,
@ManId as int,
@ItmId as int
AS
BEGIN
	
	SET NOCOUNT ON;
if(@SupId = 0 )
begin
 SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice AS TP, Discount, CostPrice AS PP , SalePrice AS MRP  
from  SCPStItem_M INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= SCPStItem_M.ItemCode)
 WHERE ManufacturerId = @ManId and SCPStItem_M.ItemTypeId  = @ItmId
 end
 else
 begin
    SELECT SCPStItem_D_Supplier.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice AS TP, Discount, CostPrice AS PP , SalePrice AS MRP  FROM SCPStItem_D_Supplier
INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPStItem_D_Supplier.ItemCode
INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_D_Supplier.ItemCode AND ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= SCPStItem_M.ItemCode)
 WHERE SupplierId = @SupId and SCPStItem_M.ItemTypeId  = @ItmId
 end
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMnthlyPurchaseSummary]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptMnthlyPurchaseSummary]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

	SELECT ItemTypeName,ISNULL(TTL_UN_AUTH,0) AS TTL_UN_AUTH,ISNULL(TTL_AUTH,0) AS TTL_AUTH,ISNULL(TTL_PUR,0) AS TTL_PUR,
    ISNULL(TTL_UN_AUTH,0)*100/ISNULL(TTL_PUR,0) as KPI FROM 
	(
	SELECT ItemTypeName,SUM(PCM.NetAmount) AS TTL_PUR,(SELECT SUM(NetAmount) FROM SCPTnGoodReceiptNote_M 
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (22,23) 
	AND SCPTnGoodReceiptNote_M.WraehouseId=SCPStWraehouseName.WraehouseId AND CAST(SCPTnGoodReceiptNote_M.TRNSCTN_DATE AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE)) AS TTL_UN_AUTH,
	(SELECT SUM(NetAmount) FROM SCPTnGoodReceiptNote_M INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (20,21) 
	AND SCPTnGoodReceiptNote_M.WraehouseId=SCPStWraehouseName.WraehouseId AND CAST(SCPTnGoodReceiptNote_M.TRNSCTN_DATE AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE))  AS TTL_AUTH FROM SCPTnGoodReceiptNote_M PCM
	INNER JOIN SCPStWraehouseName ON SCPStWraehouseName.WraehouseId = PCM.WraehouseId 
	INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = SCPStWraehouseName.ItemTypeId
	WHERE SCPStItemType.ItemTypeId=2 AND IsApproved=1 AND SCPStWraehouseName.IsAllow=1 AND CAST(PCM.TRNSCTN_DATE AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE) 
	GROUP BY SCPStWraehouseName.WraehouseId,ItemTypeName 
	UNION ALL
	SELECT ClassName,SUM(PRC.NetAmount) AS TTL_PUR,(SELECT SUM(SCPTnGoodReceiptNote_D.NetAmount) FROM SCPStItem_M
	INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPStItem_M.ClassId = CPM.ClassId 
	INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_M.TRNSCTN_ID = SCPTnGoodReceiptNote_D.PARENT_TRNSCTN_ID
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (22,23) 
	AND CAST(SCPTnGoodReceiptNote_M.TRNSCTN_DATE AS date) BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) 
	AND CAST(CONVERT(DATE,SCPTnGoodReceiptNote_M.TRNSCTN_DATE,103) AS DATE)) AS TTL_UN_AUTH,(SELECT SUM(SCPTnGoodReceiptNote_D.NetAmount) FROM SCPStItem_M
	INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPStItem_M.ClassId = CPM.ClassId 
	INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_M.TRNSCTN_ID = SCPTnGoodReceiptNote_D.PARENT_TRNSCTN_ID
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (20,21) 
	AND CAST(SCPTnGoodReceiptNote_M.TRNSCTN_DATE AS date) BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) 
	AND CAST(CONVERT(DATE,@ToDate,103) AS DATE)) AS TTL_AUTH FROM SCPStItem_M CPM
	INNER JOIN SCPStClassification ON SCPStClassification.ClassId = CPM.ClassId
	INNER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CPM.ItemCode
	INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCM.TRNSCTN_ID = PRC.PARENT_TRNSCTN_ID
	WHERE CPM.ItemTypeId=1 AND IsApproved=1 AND CAST(PRCM.TRNSCTN_DATE AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE) GROUP BY CPM.ClassId,ClassName 
	)TMP

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMonthlyInventoryDetailMSS_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryDetailMSS_M]
@WraehouseName Int,
@FirstDate varchar(50),
@LimitDate varchar(50)
as
begin
SET NOCOUNT ON
DECLARE @userData TABLE(
    
    [Date] datetime
);
DECLARE @FinalData TABLE(
    
    Year_Month varchar(50),
	OpeningClose decimal(18,2),
	purchase decimal(18,2),
	local_purchase decimal(18,2),
	issued_amt decimal(18,2),
	return_pos_amt decimal(18,2),
	rtn_suplr decimal(18,2),
	discard decimal(18,2),
	BonusQty_amt decimal(18,2),
	adj decimal(18,2),
	closing decimal(18,2)

);

insert into @userData([Date])
select CONVERT(date,inv1.CreatedDate ,103) as Date 
	from SCPTnStock_D inv1  
	where cast(inv1.CreatedDate as date) 
	between cast(CONVERT(date,@FirstDate  ,103) as date) and cast(CONVERT(date,@LimitDate  ,103) as date)
	group by CONVERT(date,inv1.CreatedDate ,103)

DECLARE @Date datetime;
DECLARE EMP_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  
  select * from @userdata;
OPEN EMP_CURSOR  
FETCH NEXT FROM EMP_CURSOR INTO  @Date
WHILE @@FETCH_Status = 0  
BEGIN  

insert into @FinalData(Year_Month,OpeningClose,purchase,local_purchase,issued_amt,return_pos_amt,rtn_suplr,discard,BonusQty_amt,adj
,closing)
exec [dbo].[Sp_SCPMonthlyInventoryStatementDaywise] @WraehouseName,@Date
FETCH NEXT FROM EMP_CURSOR INTO  @Date 
END  
CLOSE EMP_CURSOR  
DEALLOCATE EMP_CURSOR  


select *,cast(Year_Month as datetime) as Data_Dt from @FinalData order by cast(Year_Month as datetime) 

end


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMonthlyInventoryDetailPOS_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryDetailPOS_M]
@WraehouseName Int,
@FirstDate varchar(50),
@LimitDate varchar(50)
as
begin
SET NOCOUNT ON
DECLARE @userData TABLE(
    
    [Date] datetime
);
DECLARE @FinalData TABLE(
    
    Date varchar(50),
	OpeningClose decimal(18,2),
	sale decimal(18,2),
	sale_refund decimal(18,2),
	issued_amt decimal(18,2),
	refund_pos_amt decimal(18,2),	
	discard decimal(18,2),
	adj decimal(18,2),
	Closing decimal(18,2)
);

insert into @userData([Date])
select CONVERT(date,inv1.CreatedDate ,103) as Date 
	from SCPTnStock_D inv1  
	where cast(inv1.CreatedDate as date) 
	between cast(CONVERT(date,@FirstDate  ,103) as date) and cast(CONVERT(date,@LimitDate  ,103) as date)
	group by CONVERT(date,inv1.CreatedDate ,103)

DECLARE @Date datetime;
DECLARE EMP_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  
  select * from @userdata;
OPEN EMP_CURSOR  
FETCH NEXT FROM EMP_CURSOR INTO  @Date
WHILE @@FETCH_Status = 0  
BEGIN  

insert into @FinalData(Date,OpeningClose,sale,sale_refund,issued_amt,refund_pos_amt,discard,adj,Closing)
execute Sp_SCPMonthlyInventoryDetailDayWisePOS @WraehouseName,@Date
FETCH NEXT FROM EMP_CURSOR INTO  @Date 
END  
CLOSE EMP_CURSOR  
DEALLOCATE EMP_CURSOR  


select *,cast(Date as datetime) as Data_Dt from @FinalData order by cast(Date as datetime) 

end



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPatientTypeWiseSaleSummary]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPatientTypeWiseSaleSummary]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)
AS
BEGIN

SELECT TRANS_DT,BatchNo,UserName,PatientTypeName,OPNG_TM,SUM(SOLD) AS SOLD,SUM(RTN) AS RTN,CLSNG_TM FROM 
(
SELECT DISTINCT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
SCPStPatientType.PatientTypeName,(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) 
AS OPNG_TM,SUM(ROUND(Quantity*PRICE,0)) AS SOLD,ISNULL((SELECT SUM(RTN_DTL.SaleAmount) FROM SCPTnSaleRefund_D RTN_DTL
INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) 
AND RTN_MSTR.SaleRefundId=SCPTnSale_M.TRANS_ID  and RTN_MSTR.IsActive=1),0) AS RTN,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM
FROM SCPTnSale_M
INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID 
INNER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID
INNER JOIN SCPStPatientType ON SCPStPatientType.PatientTypeId=SCPTnSale_M.PatientTypeId
WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
AND SCPTnSale_M.TRANS_ID!='0' AND SCPTnSale_M.PatientIp='0'  and SCPTnSale_M.IsActive=1
GROUP BY  CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,SCPStPatientType.PatientTypeName,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)),
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)),SCPTnSale_M.TRANS_ID
UNION ALL	
SELECT DISTINCT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
SCPStPatientType.PatientTypeName,(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) 
AS OPNG_TM,SUM(ROUND(Quantity*PRICE,0)) AS SOLD,ISNULL((SELECT SUM(RTN_DTL.SaleAmount) FROM SCPTnSaleRefund_D RTN_DTL
INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) 
AND RTN_MSTR.PatinetIp=SCPTnSale_M.PatientIp  and RTN_MSTR.IsActive=1),0) AS RTN,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM
FROM SCPTnSale_M
INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID 
INNER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID
INNER JOIN SCPStPatientType ON SCPStPatientType.PatientTypeId=SCPTnSale_M.PatientTypeId
WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
AND SCPTnSale_M.PatientIp!='0'  and SCPTnSale_M.IsActive=1
GROUP BY  CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,SCPStPatientType.PatientTypeName,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)),
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)),SCPTnSale_M.PatientIp
	)TMP GROUP BY TRANS_DT,BatchNo,UserName,PatientTypeName,OPNG_TM,CLSNG_TM
	
END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPharmacySaleUserWise]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySaleUserWise]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)
AS
BEGIN

 -- SELECT TRANS_DT,BatchNo,UserName,OPNG_TM,CSH_SL,CRDT_SL,CSH_RTN,CRDT_RTN,(CSH_SL-CSH_RTN) AS CSH_NET_SL,
 -- (CRDT_SL-CRDT_RTN) AS CRDT_NET_SL,CLSNG_TM FROM
 -- (
 --   SELECT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) AS OPNG_TM,
	--ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
	--CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CSH_SL,
	--ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_SL,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND	CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) CSH_RTN,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
	--AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_RTN,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM 
	--FROM SCPTnSale_M INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
 --   INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.USR_ID = SCPStUser_M.USR_ID INNER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID
	--LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
	--LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	--WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
	--GROUP BY CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)),
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108))
 -- )TMP


   SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
 (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM FROM
  (
  select SCPTnBatchNo_D.BatchNo,-- (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoStartTime, 105)+' '+CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoStartTime,108)) AS OPNG_TM,
  (select TOP 1 (CONVERT(VARCHAR(10), CreatedDate, 105)+' '+CONVERT(VARCHAR(5),CreatedDate,108)) from SCPTnBatchNo_D PHD where BatchNo=SCPTnBatchNo_D.BatchNo 
   AND PHD.USR_ID=SCPTnBatchNo_D.USR_ID) as OPNG_TM,(select TOP 1 (CONVERT(VARCHAR(10), CloseTime, 105)+' '+CONVERT(VARCHAR(5),CloseTime,108)) from SCPTnBatchNo_D PHD
   where BatchNo=SCPTnBatchNo_D.BatchNo AND PHD.USR_ID=SCPTnBatchNo_D.USR_ID) as CLSNG_TM,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate as TRANS_DT,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0))
    FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo and SL_MSTR.IsActive=1 
	AND SL_MSTR.CRTD_BY=SCPTnBatchNo_D.USR_ID and SL_MSTR.IsActive=1),0) AS CSH_SL,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL	
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo  and SL_MSTR.IsActive=1 
	AND SL_MSTR.CRTD_BY=SCPTnBatchNo_D.USR_ID and SL_MSTR.IsActive=1),0) AS CRDT_SL,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo and RTN_MSTR.IsActive=1 
	AND RTN_MSTR.CRTD_BY=SCPTnBatchNo_D.USR_ID and RTN_MSTR.IsActive=1),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2 AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo and RTN_MSTR.IsActive=1 
	AND RTN_MSTR.CRTD_BY=SCPTnBatchNo_D.USR_ID and RTN_MSTR.IsActive=1),0) AS CRDT_RTN --,(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchNoCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchNoCloseTime,108)) AS CLSNG_TM
	 from SCPTnBatchNo_M
	INNER JOIN SCPTnBatchNo_D ON SCPTnBatchNo_M.BatchNo = SCPTnBatchNo_D.BatchNo AND SCPTnBatchNo_M.IsActive=1
	LEFT OUTER JOIN SCPTnSale_M ON SCPTnBatchNo_D.BatchNo = SCPTnSale_M.BatchNo AND SCPTnSale_M.CRTD_BY = SCPTnBatchNo_D.USR_ID AND SCPTnSale_M.IsActive=1
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_D.USR_ID = SCPStUser_M.USR_ID 
	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.PARNT_TRANS_ID=SCPTnSale_M.TRANS_ID  
	LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo AND SCPTnSaleRefund_M.IsActive=1
	LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	WHERE CAST(SCPTnBatchNo_M.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	GROUP BY SCPTnBatchNo_D.BatchNo,BatchNoStartTime, BatchNoCloseTime,SCPStUser_M.UserName, SCPTnSale_M.BatchNo, SCPTnBatchNo_M.CreatedDate,SCPTnBatchNo_D.USR_ID
	)tmp GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,OPNG_TM,CLSNG_TM,UserName ORDER BY TRANS_DT

  END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPRSummaryReport]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPRSummaryReport]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
	--SELECT ItemType.ItemTypeName,
	--	   COUNT(PRM.TRANSCTN_ID) AS No_Of_Pr,
	--	   COUNT(CASE WHEN DATEDIFF(day,PRM.CreatedDate,POD.CreatedDate) <=5  THEN PRM.TRANSCTN_ID END) AS WithinLeadTime,
	--	   COUNT(CASE WHEN  DATEDIFF(day,PRM.CreatedDate,POD.CreatedDate) >5  THEN PRM.TRANSCTN_ID END) AS Pending,
	--	   COUNT(PRDM.TRANSCTN_ID) AS Pr_Discard
	--FROM [dbo].[SCPStItemType] AS ItemType
	--INNER JOIN [SCPTnPuchaseRequisition_M] AS PRM ON PRM.ProcurementId = ItemType.ItemTypeId
	--INNER JOIN [SCPTnPurchaseOrder_D] AS POD ON POD.PurchaseRequisitionId = PRM.TRANSCTN_ID
	--LEFT JOIN [SCPTnPRDiscard_M] AS PRDM ON PRM.TRANSCTN_ID = PRDM.PurchaseRequisitionId
	--WHERE  CAST(PRM.CreatedDate as date) BETWEEN 
	--	   CAST(CONVERT(date, @paramFromDate,103) as date) AND
	--	CAST(CONVERT(date,@paramToDate,103) as date) 
	--GROUP BY ItemType.ItemTypeName

SELECT ItemTypeName,COUNT(PRC.TRANSCTN_ID) AS No_Of_Pr,COUNT(SCPTnPRDiscard_M.PurchaseRequisitionId) AS Pr_Discard,
(SELECT COUNT(PC.TRANSCTN_ID) FROM SCPTnPuchaseRequisition_M PC WHERE PC.IsApprove=1 AND PC.ProcurementId=PRC.ProcurementId
AND PC.TRANSCTN_ID IN(SELECT PurchaseRequisitionId FROM SCPTnPurchaseOrder_D) AND CAST(PC.CreatedDate AS date) BETWEEN 
CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)) AS WithinLeadTime,
(SELECT COUNT(TRANSCTN_ID) FROM(SELECT TRANSCTN_ID,(SELECT TOP 1 DATEDIFF(day,CreatedDate,DECISION_DT) FROM SCPTnApproval 
WHERE TRANS_DOC_ID=SCPTnPuchaseRequisition_M.TRANSCTN_ID ORDER BY CreatedDate DESC) AS AppDiffDays,
DATEDIFF(day,SCPTnPuchaseRequisition_M.CreatedDate,GETDATE()) As DiffDays FROM SCPTnPuchaseRequisition_M
LEFT OUTER JOIN SCPTnApproval ON SCPTnApproval.TRANS_DOC_ID = SCPTnPuchaseRequisition_M.TRANSCTN_ID
WHERE SCPTnPuchaseRequisition_M.ProcurementId=PRC.ProcurementId AND IsApprove=1 AND CAST(SCPTnPuchaseRequisition_M.CreatedDate AS date) 
BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date))TMP WHERE 
(CASE WHEN AppDiffDays IS NULL THEN DiffDays ELSE (DiffDays-AppDiffDays) END)>5 
AND TRANSCTN_ID NOT IN(SELECT PurchaseRequisitionId FROM SCPTnPurchaseOrder_D)) AS Pending FROM SCPTnPuchaseRequisition_M PRC
INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = PRC.ProcurementId
LEFT OUTER JOIN SCPTnPRDiscard_M ON SCPTnPRDiscard_M.PurchaseRequisitionId = PRC.TRANSCTN_ID AND CAST(SCPTnPRDiscard_M.CreatedDate AS date) 
BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)
WHERE IsApprove=1 AND CAST(PRC.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
AND CAST(CONVERT(date,@paramToDate,103) as date) GROUP BY PRC.ProcurementId,ItemTypeName;

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptRateAnalysis]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptRateAnalysis]
@FROM_DATE VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

DECLARE @userData TABLE(
    Month_Date VARCHAR(50)
);

DECLARE @FinalData TABLE(
    MonthNumbr INT,
    Year_Month VARCHAR(50),
	Item_Count INT,
	FRST INT,
	SCND INT,
	THRD INT,
	FRTH INT,
	FFTH INT
);

insert into @userData([Month_Date])
    select Format(CR.CreatedDate,'MMM-yyyy') from SCPStRate CR  
	WHERE CAST(CreatedDate AS DATE)>=dateadd(m, datediff (m, 0,CAST(CONVERT(date,@FROM_DATE,103) as date)), 0) 
	AND CAST(CreatedDate AS DATE)<dateadd(m, datediff (m, 0,CAST(CONVERT(date,@ToDate,103) as date))+1, 0)
	group by Format(CR.CreatedDate,'MMM-yyyy')

DECLARE @Date VARCHAR(50);
DECLARE EMP_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  
  select * from @userdata;
OPEN EMP_CURSOR  
FETCH NEXT FROM EMP_CURSOR INTO  @Date
WHILE @@FETCH_Status = 0  
BEGIN  

insert into @FinalData(MonthNumbr,Year_Month,Item_Count,FRST,SCND,THRD,FRTH,FFTH)
 SELECT MonthNumbr,Month_Year,COUNT(CC_ItemCode) AS ItemCode,SUM(FRST) AS FRST,SUM(SCND) AS SCND,SUM(THRD) AS THRD
,SUM(FRTH) AS FRTH,SUM(FFTH) AS FFTH  FROM
 (
	 SELECT MonthNumbr,Month_Year,CC_ItemCode,CASE WHEN RATIO <5 THEN 1 ELSE 0 END AS FRST,
	 CASE WHEN RATIO >=5 AND RATIO < 10 THEN 1 ELSE 0 END AS SCND,
	 CASE WHEN RATIO >=10 AND RATIO < 15 THEN 1 ELSE 0 END AS THRD,
	 CASE WHEN RATIO >=15 AND RATIO < 20 THEN 1 ELSE 0 END AS FRTH,
	 CASE WHEN RATIO >=20 THEN 1 ELSE 0 END AS FFTH  FROM
	 (
		SELECT MonthNumbr,Month_Year,CC_ItemCode,(SalePrice-CostPrice)/SalePrice*100 AS RATIO FROM
		(
		   SELECT MONTH(CAST('1.' + Month_Year AS DATETIME)) AS MonthNumbr,Month_Year,CC_ItemCode,CASE WHEN CostPrice IS NULL 
		   THEN (SELECT TOP 1 CostPrice FROM SCPStRate WHERE SCPStRate.ItemCode = CC_ItemCode AND 
		   CAST(SCPStRate.CreatedDate AS date)<DATEADD(M,1,CAST('1.' + Month_Year AS DATETIME)) 
		   ORDER BY SCPStRate.CreatedDate DESC) ELSE CostPrice END CostPrice,CASE WHEN SalePrice IS NULL 
		   THEN (SELECT TOP 1 SalePrice FROM SCPStRate WHERE SCPStRate.ItemCode = CC_ItemCode 
		   AND CAST(SCPStRate.CreatedDate AS date)<DATEADD(M,1,CAST('1.' + Month_Year AS DATETIME)) 
		   ORDER BY SCPStRate.CreatedDate DESC) ELSE SalePrice END SalePrice FROM
		   (
			  SELECT @Date as Month_Year,CC.ItemCode CC_ItemCode,SalePrice,CostPrice FROM SCPStItem_M CC
			  LEFT OUTER JOIN SCPStRate CR ON CC.ItemCode = CR.ItemCode AND Format(CR.CreatedDate,'MMM-yyyy')=@Date
			  WHERE CC.IsActive=1
		   )TMP
		)TMPP
    )TMP
 )TMPP GROUP BY Month_Year,MonthNumbr 
FETCH NEXT FROM EMP_CURSOR INTO  @Date 
END  
CLOSE EMP_CURSOR  
DEALLOCATE EMP_CURSOR  

SELECT * FROM @FinalData ORDER BY MonthNumbr

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptRateChange]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptRateChange]
	@ItemTypeId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select y.ItemCode, y.ItemName,y.Rate_Count ,y.SalePrice as Current_MRP, RT.SalePrice AS MRP, y.TradePrice as Current_TP, y.CostPrice as Current_PP, rt.TradePrice AS TP, rt.CostPrice AS PP from (
select x.ItemCode,x.ItemName,x.Rate_Count, SalePrice, CostPrice, TradePrice
 from (
select  SCPStRate.ItemCode
, COUNT(SCPStItem_M.ItemCode) AS Rate_Count, 
ItemName from SCPStRate 
INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPStRate.ItemCode 
where  DATEDIFF(DAY,SCPStRate.CreatedDate, GETDATE()) < 92 AND ItemTypeId = @ItemTypeId
group by SCPStRate.ItemCode, ItemName
) x inner join SCPStRate RT on RT.ItemCode = x.ItemCode AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
WHERE CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= x.ItemCode )
)y inner join SCPStRate RT on RT.ItemCode = y.ItemCode AND ItemRateId=(select isnull(min(ItemRateId),0) from SCPStRate 
WHERE SCPStRate.ItemCode= y.ItemCode and  DATEDIFF(DAY,SCPStRate.CreatedDate, GETDATE()) < 92)

   
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptRateChangeAnalysis]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptRateChangeAnalysis]
@FROM_DATE VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

SELECT MonthNumbr,Month_Year,COUNT(ItemCode) AS ItemCode,SUM(FRST) AS FRST,SUM(SCND) AS SCND,SUM(THRD) AS THRD
,SUM(FRTH) AS FRTH,SUM(FFTH) AS FFTH  FROM
 (
	 SELECT MonthNumbr,Month_Year,ItemCode,CASE WHEN RATIO <5 THEN 1 ELSE 0 END AS FRST,
	 CASE WHEN RATIO >=5 AND RATIO < 10 THEN 1 ELSE 0 END AS SCND,
	 CASE WHEN RATIO >=10 AND RATIO < 15 THEN 1 ELSE 0 END AS THRD,
	 CASE WHEN RATIO >=15 AND RATIO < 20 THEN 1 ELSE 0 END AS FRTH,
	  CASE WHEN RATIO >=20 THEN 1 ELSE 0 END AS FFTH  FROM
	 (
	  SELECT MONTH(CreatedDate) AS MonthNumbr,Format(CreatedDate,'MMM-yyyy') as Month_Year,
	  ItemCode,(SalePrice-CostPrice)/SalePrice*100 AS RATIO FROM SCPStRate 
	  WHERE CAST(CreatedDate AS DATE)>=dateadd(m, datediff (m, 0,CAST(CONVERT(date,@FROM_DATE,103) as date)), 0) 
	  AND CAST(CreatedDate AS DATE)<dateadd(m, datediff (m, 0,CAST(CONVERT(date,@ToDate,103) as date))+1, 0)
	 )TMP
 )TMPP GROUP BY Month_Year,MonthNumbr ORDER BY MonthNumbr

 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptSummaryItemDiscountByManufacturer]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptSummaryItemDiscountByManufacturer]
@paramItemTypeId INT,
@paramFromDate NVARCHAR(50),
@paramToDate NVARCHAR(50)
AS
BEGIN
SELECT TotalPurchase,DiscountValue,CONVERT(VARCHAR,ISNULL((Cast(DiscountValue as float)/TotalPurchase)*100 ,0))AS PercentageOfDiscountValue
FROM 
(
	SELECT  SUM(ItemPurchaseD.NetAmount) AS TotalPurchase,
			SUM(CASE WHEN DiscountType=1 THEN (DiscountValue) ELSE ((DiscountValue/100)*TotalAmount) END) DiscountValue ,
			SUM(CASE WHEN ItemPurchaseD.DiscountValue =0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfNotDiscountItem,
			SUM(CASE WHEN ItemPurchaseD.DiscountValue !=0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfDiscountItem
	FROM [dbo].SCPTnGoodReceiptNote_D AS ItemPurchaseD
	INNER JOIN [dbo].SCPStItem_M AS Item ON Item.ItemCode = ItemPurchaseD.ItemCode
	WHERE  CAST(ItemPurchaseD.CreatedDate as date) BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
		   AND CAST(CONVERT(date,@paramToDate,103) as date)
	AND Item.ItemTypeId = @paramItemTypeId
)TMP

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPUpdateCloseItemRate]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE proc [dbo].[Sp_SCPUpdateCloseItemRate]
	(
	@from_date varchar(50),
	@code varchar(50)
	)
	as
	begin
	update SCPStRate set ToDate=DATEADD(day,-1,@from_date) where ItemCode=@code and CONVERT(date, getdate()) between FromDate and ToDate
	end


GO
/****** Object:  UserDefinedFunction [dbo].[Fn_SCPDateFormate]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fn_SCPDateFormate] (@input VARCHAR(250))
RETURNS VARCHAR(250)
AS BEGIN
    DECLARE @date VARCHAR(250)

    SET @date = FORMAT(CAST(CONVERT(date,@input,103) as date), 'MM-yyyy');

    RETURN @date
END



GO
/****** Object:  UserDefinedFunction [dbo].[Fn_SCPGetMonthName]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fn_SCPGetMonthName] (@input varchar(2))
RETURNS VARCHAR(250)
AS BEGIN
    DECLARE @Work VARCHAR(250)
	select @work=
	(case @input 
		when '1'   then  'Jan'
		when '2'   then  'Feb' 
		when '3'   then  'Mar'
		when '4'   then  'Apr'  
		when '5'   then  'May'
		when '6'   then  'Jun' 
		when '7'   then  'Jul'
		when '8'   then  'Aug'  
		when '9'   then  'Sep'
		when '10'  then  'Oct' 
		when '11'  then  'Nov'
		when '12'  then  'Dec'  
		else '' end)
    --SET @Work = REPLACE(@Work, 'www.', '')
    --SET @Work = REPLACE(@Work, '.com', '')

    RETURN @work
END


GO
/****** Object:  Table [dbo].[SCPStAlertType_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStAlertType_D](
	[AlertMappingId] [bigint] IDENTITY(1,1) NOT NULL,
	[AlertTypeId] [bigint] NOT NULL,
	[DepartmentId] [bigint] NOT NULL,
	[UserId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AlertMappingId] PRIMARY KEY CLUSTERED 
(
	[AlertMappingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStAlertType_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStAlertType_M](
	[AlerTypeId] [bigint] IDENTITY(1,1) NOT NULL,
	[AlertType] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AlertTypeId] PRIMARY KEY CLUSTERED 
(
	[AlerTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStApproval]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStApproval](
	[ApprovalLevelId] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentType] [varchar](50) NOT NULL,
	[ClassificationId] [bigint] NOT NULL,
	[Designation] [varchar](50) NOT NULL,
	[Limit] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ApprovalLevelId] PRIMARY KEY CLUSTERED 
(
	[ApprovalLevelId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStAutoParLevel_Log]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStAutoParLevel_Log](
	[AutoParLevelLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[ParLevelId] [bigint] NOT NULL,
	[ParLevelDays] [money] NOT NULL,
	[ParLevelApplyDays] [int] NOT NULL,
	[ParLevelConsumptionDays] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AutoParLevelLogId] PRIMARY KEY CLUSTERED 
(
	[AutoParLevelLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStAutoParLevel_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStAutoParLevel_M](
	[AutoParLevelId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[ParLevelId] [bigint] NOT NULL,
	[ParLevelDays] [money] NOT NULL,
	[ParLevelApplyDays] [int] NOT NULL,
	[ParLevelConsumptionDays] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AutoParLevelId] PRIMARY KEY CLUSTERED 
(
	[AutoParLevelId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStCategory](
	[CategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[CategoryName] [varchar](max) NOT NULL,
	[SubClassId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CategoryId] PRIMARY KEY CLUSTERED 
(
	[CategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStCity]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStCity](
	[CityId] [bigint] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](50) NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CityId] PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStClassification]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStClassification](
	[ClassId] [bigint] IDENTITY(1,1) NOT NULL,
	[ClassName] [varchar](max) NOT NULL,
	[ItemTypeId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ClassId] PRIMARY KEY CLUSTERED 
(
	[ClassId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStCompany]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStCompany](
	[CompanyId] [bigint] IDENTITY(1,1) NOT NULL,
	[CompanyName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CompanyPRF] [varchar](50) NOT NULL,
	[CompanyCode] [varchar](50) NOT NULL,
	[HIMSCompanyId] [bigint] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CompanyId] PRIMARY KEY CLUSTERED 
(
	[CompanyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStConsultant]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStConsultant](
	[ConsultantId] [bigint] IDENTITY(1,1) NOT NULL,
	[ConsultantName] [varchar](50) NOT NULL,
	[QualificationId] [bigint] NOT NULL,
	[SpecialityId] [bigint] NOT NULL,
	[HIMSConsultantId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ConsultantId] PRIMARY KEY CLUSTERED 
(
	[ConsultantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStConsultantReferral_Log]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStConsultantReferral_Log](
	[ConsultantReferralLodI] [int] IDENTITY(1,1) NOT NULL,
	[ConsultantId] [bigint] NOT NULL,
	[AvgPatients] [int] NOT NULL,
	[Percentage] [decimal](18, 2) NOT NULL,
	[NoOfDays] [int] NULL,
	[PerPrescripAmt] [bigint] NOT NULL,
	[StandardAmount] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[Status] [varchar](max) NULL,
	[UserName] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStConsultantReferral_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStConsultantReferral_M](
	[ConsultantReferralId] [int] IDENTITY(1,1) NOT NULL,
	[ConsultantId] [bigint] NOT NULL,
	[AvgPatients] [int] NOT NULL,
	[Percentage] [decimal](18, 2) NOT NULL,
	[NoOfDays] [int] NULL,
	[PerPrescripAmt] [bigint] NOT NULL,
	[StandardAmount] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConsultantReferralId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStConsultantReferralComments]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStConsultantReferralComments](
	[ConsultantReferralCommentId] [int] IDENTITY(1,1) NOT NULL,
	[ConsultantId] [bigint] NOT NULL,
	[ZoneId] [int] NULL,
	[ReasonIdID] [int] NULL,
	[StandardAmount] [bigint] NOT NULL,
	[ActualAmount] [bigint] NOT NULL,
	[erenceDiff] [bigint] NOT NULL,
	[StandardAvgPrescription] [nvarchar](max) NOT NULL,
	[ReferralPercentage] [nvarchar](max) NOT NULL,
	[FromDate] [datetime] NOT NULL,
	[ToDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConsultantReferralCommentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStConsultantReferralReasonId]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[SCPStConsultantReferralReasonId](
	[ConsultantReferralReasonIdId] [int] IDENTITY(1,1) NOT NULL,
	[ReasonIdDescription] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConsultantReferralReasonIdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStConsultantReferralZone]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStConsultantReferralZone](
	[ZoneId] [bigint] IDENTITY(1,1) NOT NULL,
	[ZoneName] [varchar](50) NOT NULL,
	[ZoneColor] [varchar](50) NULL,
	[RangeFrom] [int] NOT NULL,
	[RangeTo] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ZoneId] PRIMARY KEY CLUSTERED 
(
	[ZoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStCountry]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStCountry](
	[CountryId] [bigint] IDENTITY(1,1) NOT NULL,
	[CountryName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CountryI] PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStDeligation]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStDeligation](
	[DeligationId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[DeligatedUserId] [int] NOT NULL,
	[FromDate] [datetime] NOT NULL,
	[ToDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DeligationId] PRIMARY KEY CLUSTERED 
(
	[DeligationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStDepartment]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStDepartment](
	[DepartmentId] [bigint] IDENTITY(1,1) NOT NULL,
	[DepartmentName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DepartmentId] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStDosage]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStDosage](
	[DosageId] [bigint] IDENTITY(1,1) NOT NULL,
	[DosageName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DosageId] PRIMARY KEY CLUSTERED 
(
	[DosageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStDose]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStDose](
	[DoseId] [bigint] IDENTITY(1,1) NOT NULL,
	[DoseName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DoseId] PRIMARY KEY CLUSTERED 
(
	[DoseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStEmployee]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStEmployee](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeCode] [varchar](50) NULL,
	[EmployeeName] [varchar](50) NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_CRP_EmployeeId] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStEmployeeGroup]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStEmployeeGroup](
	[EmployeeGroupId] [bigint] IDENTITY(1,1) NOT NULL,
	[EmployeeGroup] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_EmployeeGroupId] PRIMARY KEY CLUSTERED 
(
	[EmployeeGroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStExpiryCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStExpiryCategory](
	[ExpiryCategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[ExpiryCategoryT] [varchar](50) NOT NULL,
	[ExpiryDurationFrom] [int] NOT NULL,
	[ExpiryDurationFromType] [int] NOT NULL,
	[ExpiryDurationTo] [int] NOT NULL,
	[ExpiryDurationToType] [int] NOT NULL,
	[IntimationTime] [int] NOT NULL,
	[IntimationTimeType] [int] NOT NULL,
	[OffShelfTime] [int] NOT NULL,
	[OffShelfTimeType] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ExpiryCategoryId] PRIMARY KEY CLUSTERED 
(
	[ExpiryCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStFeild]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStFeild](
	[ConsultantFeildId] [bigint] IDENTITY(1,1) NOT NULL,
	[CConsultantFeildName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ConsultantFeildId] PRIMARY KEY CLUSTERED 
(
	[ConsultantFeildId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStFormsList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStFormsList](
	[FormCode] [varchar](50) NOT NULL,
	[FormName] [varchar](50) NOT NULL,
	[FormDescription] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_FormCode] PRIMARY KEY CLUSTERED 
(
	[FormCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStFormulary]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStFormulary](
	[FormularyId] [bigint] IDENTITY(1,1) NOT NULL,
	[FormularyName] [varchar](50) NOT NULL,
	[PriorityNo] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_FormularyId] PRIMARY KEY CLUSTERED 
(
	[FormularyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStGeneric]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStGeneric](
	[GenericId] [bigint] IDENTITY(1,1) NOT NULL,
	[GenericName] [varchar](max) NOT NULL,
	[SubCategoryId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_GenericId] PRIMARY KEY CLUSTERED 
(
	[GenericId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStHoliday]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPStHoliday](
	[HolidayId] [int] IDENTITY(1,1) NOT NULL,
	[HolidayDate] [datetime] NOT NULL,
	[Title] [nvarchar](50) NULL,
	[IsActive] [bit] NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
 CONSTRAINT [PK_HolidayId] PRIMARY KEY CLUSTERED 
(
	[HolidayId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPStIsApprovedBy]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStIsApprovedBy](
	[IsApprovedById] [int] IDENTITY(1,1) NOT NULL,
	[ConsultantId] [int] NULL,
	[IsApprovedMemberName] [varchar](50) NULL,
	[IsActive] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[RowStamp] [timestamp] NULL,
 CONSTRAINT [PK_IsApprovedById] PRIMARY KEY CLUSTERED 
(
	[IsApprovedById] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItem_D_Shelf]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItem_D_Shelf](
	[ItemShelfMappingId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[ShelfId] [bigint] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemShelfMappingId] PRIMARY KEY CLUSTERED 
(
	[ItemShelfMappingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItem_D_Supplier]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItem_D_Supplier](
	[ItemSupplierMappingId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[SupplierId] [bigint] NOT NULL,
	[DefaultVendor] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemSupplierMappingId] PRIMARY KEY CLUSTERED 
(
	[ItemSupplierMappingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItem_D_WraehouseName]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItem_D_WraehouseName](
	[CHILD_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CRP010D1] PRIMARY KEY CLUSTERED 
(
	[CHILD_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItem_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItem_M](
	[ItemCode] [varchar](50) NOT NULL,
	[ItemName] [varchar](max) NOT NULL,
	[Pneumonics] [varchar](50) NULL,
	[ItemTypeId] [bigint] NOT NULL,
	[ClassId] [bigint] NOT NULL,
	[SubClassId] [bigint] NOT NULL,
	[CategoryId] [bigint] NOT NULL,
	[SubCategoryId] [bigint] NOT NULL,
	[GenericId] [bigint] NOT NULL,
	[DosageFormId] [bigint] NULL,
	[FormularyId] [bigint] NULL,
	[PackingQuantity] [bigint] NULL,
	[ItemPackingQuantity] [bigint] NULL,
	[ItemUnit] [bigint] NOT NULL,
	[ManufacturerId] [bigint] NULL,
	[RouteOfAdministrationId] [bigint] NULL,
	[SignaId] [bigint] NULL,
	[StrengthId] [bigint] NULL,
	[ExpiryCategoryId] [bigint] NULL,
	[MedicalNeedItem] [bit] NULL,
	[FreezItem] [bit] NULL,
	[OnHold] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemCode] PRIMARY KEY CLUSTERED 
(
	[ItemCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_CRP010M] UNIQUE NONCLUSTERED 
(
	[ItemCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItem_M_RecommendationApproval]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItem_M_RecommendationApproval](
	[ItemRecomendationApprovalId] [bigint] IDENTITY(1,1) NOT NULL,
	[RecommendedMemberId] [int] NULL,
	[IsApprovedById] [int] NULL,
	[ForecastedConsumptionPrMonth] [int] NULL,
	[ItemCode] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [ItemRecomendationApprovalId] PRIMARY KEY CLUSTERED 
(
	[ItemRecomendationApprovalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItemFormWraehouseNameFeild]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItemFormWraehouseNameFeild](
	[FormId] [varchar](50) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[WraehouseName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsEnable] [bit] NOT NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStItemType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStItemType](
	[ItemTypeId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemTypeName] [varchar](50) NOT NULL,
	[AlllowSale] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemTypeId] PRIMARY KEY CLUSTERED 
(
	[ItemTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStKit_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStKit_D](
	[KitDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[KitId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_KitDetailId] PRIMARY KEY CLUSTERED 
(
	[KitDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStKit_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStKit_M](
	[KitId] [varchar](50) NOT NULL,
	[KitName] [varchar](50) NOT NULL,
	[KitCategoryId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_KitId] PRIMARY KEY CLUSTERED 
(
	[KitId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStKitCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStKitCategory](
	[KitCategoryIdegoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[KitCategoryId] [varchar](50) NOT NULL,
	[PatientCategoryId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_KitCategoryIdegoryId] PRIMARY KEY CLUSTERED 
(
	[KitCategoryIdegoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStManufactutrer]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStManufactutrer](
	[ManufacturerId] [bigint] IDENTITY(1,1) NOT NULL,
	[ManufacturerName] [varchar](max) NOT NULL,
	[ManufacturerCategoryId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ManufacturerId] PRIMARY KEY CLUSTERED 
(
	[ManufacturerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStManufactutrerCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStManufactutrerCategory](
	[ManufacturerCategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[ManufacturerCategoryName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ManufacturerCategoryId] PRIMARY KEY CLUSTERED 
(
	[ManufacturerCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStMeasuringUnit]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStMeasuringUnit](
	[UnitId] [bigint] IDENTITY(1,1) NOT NULL,
	[UnitName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_UnitId] PRIMARY KEY CLUSTERED 
(
	[UnitId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStNamePrefix]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStNamePrefix](
	[NamePrefixId] [bigint] IDENTITY(1,1) NOT NULL,
	[NamePrefixName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_NamePrefixId] PRIMARY KEY CLUSTERED 
(
	[NamePrefixId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStOldItemMapping]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStOldItemMapping](
	[OldItemCode] [varchar](50) NULL,
	[NewItemCode] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStParLevel]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStParLevel](
	[ParLevelId] [bigint] IDENTITY(1,1) NOT NULL,
	[ParLevelName] [varchar](max) NOT NULL,
	[SerialNo] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ParLevelId] PRIMARY KEY CLUSTERED 
(
	[ParLevelId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStParLevelAssignment_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStParLevelAssignment_D](
	[ParLevelAssignmentDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[ParLevelAssignmentId] [varchar](50) NOT NULL,
	[ParLevelId] [bigint] NOT NULL,
	[Currentlevel] [int] NOT NULL,
	[NewLevel] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CRP014D] PRIMARY KEY CLUSTERED 
(
	[ParLevelAssignmentDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStParLevelAssignment_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStParLevelAssignment_M](
	[ParLevelAssignmentId] [varchar](50) NOT NULL,
	[ParLevelAssignmentDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[AvgPerDay] [int] NULL,
	[ParLevelType] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_CRP014M] PRIMARY KEY CLUSTERED 
(
	[ParLevelAssignmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStPartner]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStPartner](
	[PartnerId] [bigint] IDENTITY(1,1) NOT NULL,
	[PartnerName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PartnerId] PRIMARY KEY CLUSTERED 
(
	[PartnerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStPatientCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStPatientCategory](
	[PatientCategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[PatientCategoryName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PatientCategoryId] PRIMARY KEY CLUSTERED 
(
	[PatientCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStPatientSubCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStPatientSubCategory](
	[PatientSubCategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[PatientSubCategoryName] [varchar](50) NOT NULL,
	[PatientCategoryId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PatientSubCategoryId] PRIMARY KEY CLUSTERED 
(
	[PatientSubCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStPatientType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStPatientType](
	[PatientTypeId] [bigint] IDENTITY(1,1) NOT NULL,
	[PatientTypeName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PatientTypeId] PRIMARY KEY CLUSTERED 
(
	[PatientTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStPaymentMode]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStPaymentMode](
	[ModeOfPaymentId] [bigint] IDENTITY(1,1) NOT NULL,
	[ModeOfPaymentName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ModeOfPaymentId] PRIMARY KEY CLUSTERED 
(
	[ModeOfPaymentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStPaymentTerm]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStPaymentTerm](
	[PaymentTermId] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentTermName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PaymentTermId] PRIMARY KEY CLUSTERED 
(
	[PaymentTermId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStProcurementNameType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStProcurementNameType](
	[ProcurementNameId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProcurementName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ProcurementNameId] PRIMARY KEY CLUSTERED 
(
	[ProcurementNameId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStQualification]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStQualification](
	[QualificationId] [bigint] IDENTITY(1,1) NOT NULL,
	[QualificationName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_QualificationId] PRIMARY KEY CLUSTERED 
(
	[QualificationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStRack]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStRack](
	[RackId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[RackName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_RackId] PRIMARY KEY CLUSTERED 
(
	[RackId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStRate]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStRate](
	[ItemRateId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[FromDate] [datetime] NOT NULL,
	[ToDate] [datetime] NOT NULL,
	[SalePrice] [money] NOT NULL,
	[CostPrice] [money] NOT NULL,
	[TradePrice] [money] NOT NULL,
	[Discount] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemRateId] PRIMARY KEY CLUSTERED 
(
	[ItemRateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStReasonId]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStReasonId](
	[ReasonId] [int] IDENTITY(1,1) NOT NULL,
	[ReasonText] [varchar](max) NOT NULL,
	[DocumentType] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ReasonId] PRIMARY KEY CLUSTERED 
(
	[ReasonId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStRecommendedBy]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStRecommendedBy](
	[RecommendedMemberId] [int] IDENTITY(1,1) NOT NULL,
	[ConsultantId] [int] NULL,
	[RecommendedMemberName] [varchar](50) NULL,
	[IsActive] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[RowStamp] [timestamp] NULL,
 CONSTRAINT [PK_RecommendedMemberI] PRIMARY KEY CLUSTERED 
(
	[RecommendedMemberId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStReportsList]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStReportsList](
	[ReportCode] [varchar](50) NOT NULL,
	[ReportName] [varchar](50) NOT NULL,
	[FormDescription] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ReportCode] PRIMARY KEY CLUSTERED 
(
	[ReportCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStRouteOfAdministration]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStRouteOfAdministration](
	[RouteOfAdministrationId] [bigint] IDENTITY(1,1) NOT NULL,
	[RouteOfAdministrationTitle] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_RouteOfAdministrationId] PRIMARY KEY CLUSTERED 
(
	[RouteOfAdministrationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStShelf]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStShelf](
	[ShelfId] [bigint] IDENTITY(1,1) NOT NULL,
	[ShelfName] [varchar](50) NOT NULL,
	[RackId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ShelfId] PRIMARY KEY CLUSTERED 
(
	[ShelfId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStShift]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStShift](
	[ShiftId] [bigint] IDENTITY(1,1) NOT NULL,
	[ShiftName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ShiftId] PRIMARY KEY CLUSTERED 
(
	[ShiftId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSigna]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSigna](
	[SignaId] [bigint] IDENTITY(1,1) NOT NULL,
	[SignaName] [varchar](max) NOT NULL,
	[SignaQuantity] [int] NOT NULL,
	[SignaLabel] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SignaId] PRIMARY KEY CLUSTERED 
(
	[SignaId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSpeciality]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSpeciality](
	[ConsultantSpecialityId] [bigint] IDENTITY(1,1) NOT NULL,
	[ConsultantSpecialityName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ConsultantFeildId] [bigint] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ConsultantSpecialityId] PRIMARY KEY CLUSTERED 
(
	[ConsultantSpecialityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStStandardValue]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStStandardValue](
	[StandardFeildId] [bigint] IDENTITY(1,1) NOT NULL,
	[StandardFeildName] [varchar](max) NOT NULL,
	[StandardFeildValue] [varchar](max) NOT NULL,
	[FormCode] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_StandardFeildId] PRIMARY KEY CLUSTERED 
(
	[StandardFeildId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStStockConsumptionType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStStockConsumptionType](
	[ItemConsumptionIdTypeId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemConsumptionIdTypeName] [varchar](50) NOT NULL,
	[RangeFrom] [int] NOT NULL,
	[RangeTo] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemConsumptionIdTypeId] PRIMARY KEY CLUSTERED 
(
	[ItemConsumptionIdTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStStrengthId]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStStrengthId](
	[StrengthIdId] [bigint] IDENTITY(1,1) NOT NULL,
	[StrengthIdName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_StrengthIdId] PRIMARY KEY CLUSTERED 
(
	[StrengthIdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSubCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSubCategory](
	[SubCategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[SubCategoryName] [varchar](max) NOT NULL,
	[CategoryId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SubCategoryId] PRIMARY KEY CLUSTERED 
(
	[SubCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSubClassification]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSubClassification](
	[SubClassId] [bigint] IDENTITY(1,1) NOT NULL,
	[SubClassName] [varchar](max) NOT NULL,
	[ClassId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SubClassId] PRIMARY KEY CLUSTERED 
(
	[SubClassId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSupplier]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSupplier](
	[SupplierId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemTypeId] [bigint] NOT NULL,
	[SupplierCategoryId] [bigint] NOT NULL,
	[SupplierShortName] [varchar](50) NULL,
	[SupplierLongName] [varchar](max) NOT NULL,
	[FaxNo] [varchar](50) NOT NULL,
	[STRegistrationNo] [varchar](50) NOT NULL,
	[SaleTaxNo] [varchar](50) NULL,
	[AmountLimit] [decimal](18, 0) NULL,
	[ContactNo1] [varchar](50) NOT NULL,
	[ContactNo2] [varchar](50) NOT NULL,
	[Address] [varchar](max) NOT NULL,
	[DaysLimit] [int] NOT NULL,
	[LeadTime] [int] NULL,
	[PaymentDayType] [int] NOT NULL,
	[PaymentDate] [int] NULL,
	[PaymentDay] [int] NULL,
	[PaymentDayDetail] [int] NULL,
	[OrderDayType] [int] NULL,
	[OrderDate] [int] NULL,
	[OrderDay] [int] NULL,
	[OrderDayDetail] [int] NULL,
	[VendorChartId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SupplierId] PRIMARY KEY CLUSTERED 
(
	[SupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSupplierCategory]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSupplierCategory](
	[SupplierCategoryId] [bigint] IDENTITY(1,1) NOT NULL,
	[SupplierCategoryName] [varchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SupplierCategoryId] PRIMARY KEY CLUSTERED 
(
	[SupplierCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStSystemInformation]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStSystemInformation](
	[SystemInformationId] [bigint] IDENTITY(1,1) NOT NULL,
	[CounterName] [varchar](50) NOT NULL,
	[IpAddress] [varchar](50) NOT NULL,
	[SystemName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SystemInformation] PRIMARY KEY CLUSTERED 
(
	[SystemInformationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStTimeType]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStTimeType](
	[TimeDurationTypeId] [int] IDENTITY(1,1) NOT NULL,
	[TimeDurationType] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_TimeDurationType] PRIMARY KEY CLUSTERED 
(
	[TimeDurationTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStUser_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStUser_D](
	[UserRightId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[FormCode] [varchar](50) NOT NULL,
	[AllowAdd] [bit] NOT NULL,
	[AllowEdit] [bit] NOT NULL,
	[AllowView] [bit] NOT NULL,
	[AllowDelete] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_UserRightId] PRIMARY KEY CLUSTERED 
(
	[UserRightId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStUser_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStUser_M](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](50) NOT NULL,
	[EmployeeCode] [bigint] NULL,
	[UserPassword] [varchar](50) NULL,
	[PasswordExpiryDate] [datetime] NULL,
	[ADAccount] [varchar](50) NOT NULL,
	[UserGroupId] [bigint] NULL,
	[IsDeligated] [bit] NULL,
	[EmployeeGroupId] [bigint] NULL,
	[Remarks] [varchar](50) NULL,
	[IsChangePassword] [bit] NOT NULL,
	[IsPasswordNeverExpire] [bit] NOT NULL,
	[IsLocked] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_UserId] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStUserGroup_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStUserGroup_D](
	[UserGroupDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserGroupId] [bigint] NOT NULL,
	[FormCode] [varchar](50) NOT NULL,
	[AllowAdd] [bit] NOT NULL,
	[AllowEdit] [bit] NOT NULL,
	[AllowView] [bit] NOT NULL,
	[AllowDelete] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_UserGroupDetailId] PRIMARY KEY CLUSTERED 
(
	[UserGroupDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStUserGroup_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStUserGroup_M](
	[UserGroupId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserGroup] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_UserGroupId] PRIMARY KEY CLUSTERED 
(
	[UserGroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStVendorChart]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStVendorChart](
	[VendorChartId] [bigint] IDENTITY(1,1) NOT NULL,
	[VendorChart] [varchar](50) NOT NULL,
	[LeadTime] [int] NOT NULL,
	[TotalSupplyDays] [int] NOT NULL,
	[WeeklyVisit] [int] NOT NULL,
	[VisitAfterDays] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[UpdatedBy] [int] NULL,
	[UpdatedDate] [datetime] NULL,
	[RowStamp] [timestamp] NULL,
 CONSTRAINT [PK_VendorChartId] PRIMARY KEY CLUSTERED 
(
	[VendorChartId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPStWraehouse]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPStWraehouse](
	[WraehouseId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseName] [varchar](50) NOT NULL,
	[ItemTypeId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsAllow] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_WraehouseId] PRIMARY KEY CLUSTERED 
(
	[WraehouseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnAdjustment_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnAdjustment_D](
	[AdjustmentDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[AdjustmentId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[StockType] [int] NOT NULL,
	[AdjustedQuantity] [int] NOT NULL,
	[ItemBalance] [int] NOT NULL,
	[ItemRate] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AdjustmentDetailId] PRIMARY KEY CLUSTERED 
(
	[AdjustmentDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnAdjustment_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnAdjustment_M](
	[AdjustmentId] [varchar](50) NOT NULL,
	[AdjustmentDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[IsApprove] [bit] NULL,
	[IsReject] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AdjustmentId] PRIMARY KEY CLUSTERED 
(
	[AdjustmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnAlert_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnAlert_D](
	[AlertChildId] [bigint] IDENTITY(1,1) NOT NULL,
	[AlertId] [varchar](50) NOT NULL,
	[isView] [bit] NOT NULL,
	[ShowLaterCount] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AlertChildId] PRIMARY KEY CLUSTERED 
(
	[AlertChildId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnAlert_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnAlert_M](
	[AlertId] [varchar](50) NOT NULL,
	[AlertTypeId] [bigint] NOT NULL,
	[AlertCount] [int] NOT NULL,
	[Status] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_AlertId] PRIMARY KEY CLUSTERED 
(
	[AlertId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnApproval]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnApproval](
	[ApprovalId] [bigint] IDENTITY(1,1) NOT NULL,
	[FormCode] [varchar](50) NULL,
	[TransactionDocumentName] [varchar](50) NOT NULL,
	[TransactionDocumentId] [varchar](50) NOT NULL,
	[FromUser] [int] NOT NULL,
	[ToUser] [int] NOT NULL,
	[IsIsApproved] [bit] NULL,
	[IsRejected] [bit] NULL,
	[DecisionDate] [datetime] NULL,
	[Comment] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ApprovalId] PRIMARY KEY CLUSTERED 
(
	[ApprovalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnAutoParLevel]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPTnAutoParLevel](
	[ParLevelExecutionId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[ExecutionStartTime] [datetime] NOT NULL,
	[ExecutionEndTime] [datetime] NOT NULL,
	[ItemsApplied] [int] NOT NULL,
	[IsCycleCompleted] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ParLevelExecutionId] PRIMARY KEY CLUSTERED 
(
	[ParLevelExecutionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPTnbatch_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnbatch_D](
	[BatchDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[UserId] [int] NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[CloseTime] [datetime] NULL,
	[OpeningClose] [money] NOT NULL,
	[ClosingBalance] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_BatchDetail] PRIMARY KEY CLUSTERED 
(
	[BatchDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnBatch_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnBatch_M](
	[BatchId] [bigint] IDENTITY(1,1) NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[UserId] [int] NOT NULL,
	[TerminalName] [varchar](50) NOT NULL,
	[BatchStartTime] [datetime] NOT NULL,
	[BatchCloseTime] [datetime] NULL,
	[OpeningClose] [money] NOT NULL,
	[BatchAmount] [money] NOT NULL,
	[ClosingBalance] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_BatchId] PRIMARY KEY CLUSTERED 
(
	[BatchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnDemand_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnDemand_D](
	[DemandDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[DemandId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[ItemBalance] [int] NOT NULL,
	[MinLevel] [int] NOT NULL,
	[MaxLevel] [int] NOT NULL,
	[DemandQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[ReasonIdId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DemandDetailId] PRIMARY KEY CLUSTERED 
(
	[DemandDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnDemand_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnDemand_M](
	[DemandId] [varchar](50) NOT NULL,
	[DemandDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[DemandType] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DemandId] PRIMARY KEY CLUSTERED 
(
	[DemandId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnDemandDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnDemandDiscard_D](
	[DemandDiscardDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[DemandDiscardId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[DemandQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[RemainingQty] [int] NOT NULL,
	[DiscardReasonIdId] [bigint] NOT NULL,
	[DiscardReasonId] [varchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DemandDiscardDetailId] PRIMARY KEY CLUSTERED 
(
	[DemandDiscardDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnDemandDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnDemandDiscard_M](
	[DemandDiscardId] [varchar](50) NOT NULL,
	[DemandDiscardDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[DemandId] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_DemandDiscardId] PRIMARY KEY CLUSTERED 
(
	[DemandDiscardId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnFreezItem]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnFreezItem](
	[FreezId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[PurchaseOrderNo] [varchar](50) NOT NULL,
	[GoodReceiptNo] [varchar](50) NOT NULL,
	[SupplyPercentage] [money] NOT NULL,
	[IsFreez] [bit] NOT NULL,
	[FreezDate] [datetime] NOT NULL,
	[UnFreezDatee] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_FreezId] PRIMARY KEY CLUSTERED 
(
	[FreezId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnGoodReceiptNote_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnGoodReceiptNote_D](
	[GoodReceiptNoteDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[GoodReceiptNoteId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[OrderQty] [int] NOT NULL,
	[RecievedQty] [int] NOT NULL,
	[BonusQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[OldItemRate] [money] NULL,
	[ItemRate] [money] NOT NULL,
	[SalePrice] [money] NOT NULL,
	[OldSalePrice] [money] NULL,
	[TotalAmount] [money] NOT NULL,
	[DiscountType] [int] NOT NULL,
	[DiscountValue] [money] NOT NULL,
	[AfterDiscountAmount] [money] NOT NULL,
	[SaleTax] [money] NOT NULL,
	[NetAmount] [money] NOT NULL,
	[ExpiryDate] [datetime] NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_GoodReceiptNoteDetailId] PRIMARY KEY CLUSTERED 
(
	[GoodReceiptNoteDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnGoodReceiptNote_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnGoodReceiptNote_M](
	[GoodReceiptNoteId] [varchar](50) NOT NULL,
	[GoodReceiptNoteDate] [datetime] NOT NULL,
	[GRNType] [int] NULL,
	[WraehouseId] [bigint] NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsReject] [bit] NULL,
	[SupplierId] [bigint] NOT NULL,
	[PurchaseOrderId] [varchar](50) NOT NULL,
	[InvoiceNo] [varchar](50) NULL,
	[InvoiceDate] [datetime] NULL,
	[ChallanNo] [varchar](50) NOT NULL,
	[ChallanDate] [datetime] NOT NULL,
	[TotalAmount] [money] NOT NULL,
	[TotalSaleTax] [money] NOT NULL,
	[GRNAmount] [money] NOT NULL,
	[TotalDiscount] [money] NOT NULL,
	[NetAmount] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[PrintDate] [datetime] NULL,
 CONSTRAINT [PK_GoodReceiptNoteId] PRIMARY KEY CLUSTERED 
(
	[GoodReceiptNoteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnGoodReturn_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnGoodReturn_D](
	[GoodReturnDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[GoodReturnId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[ReturnQty] [int] NOT NULL,
	[ReturnReasonIdId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_GoodReturnDetailI] PRIMARY KEY CLUSTERED 
(
	[GoodReturnDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnGoodReturn_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnGoodReturn_M](
	[GoodReturnId] [varchar](50) NOT NULL,
	[GoodReturnDate] [datetime] NOT NULL,
	[DepartmentId] [bigint] NOT NULL,
	[WarehouseId] [bigint] NOT NULL,
	[IsApproved] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_GoodReturnId] PRIMARY KEY CLUSTERED 
(
	[GoodReturnId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnIndent_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnIndent_D](
	[IndentDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[IndentId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[ItemName] [varchar](50) NOT NULL,
	[RequestedQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_IndentDetailId] PRIMARY KEY CLUSTERED 
(
	[IndentDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnIndent_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnIndent_M](
	[IndentId] [varchar](50) NOT NULL,
	[IndentDate] [datetime] NOT NULL,
	[DepartmentId] [int] NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsApprove] [bit] NULL,
	[IsReject] [bit] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_IndentId] PRIMARY KEY CLUSTERED 
(
	[IndentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnIndentDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnIndentDiscard_D](
	[IndentDiscardDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[IndentDiscardId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[RequestedQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[RemainingQty] [int] NOT NULL,
	[DiscardReasonIdId] [bigint] NOT NULL,
	[DiscardReasonId] [varchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_IndentDiscardDetailId] PRIMARY KEY CLUSTERED 
(
	[IndentDiscardDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnIndentDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnIndentDiscard_M](
	[IndentDiscardId] [varchar](50) NOT NULL,
	[DiscardDate] [datetime] NOT NULL,
	[DepartmentId] [bigint] NOT NULL,
	[IndentId] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_IndentDiscardId] PRIMARY KEY CLUSTERED 
(
	[IndentDiscardId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnInPatient]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnInPatient](
	[EntryId] [bigint] IDENTITY(1,1) NOT NULL,
	[PatientIp] [varchar](50) NOT NULL,
	[PatientTypeId] [int] NOT NULL,
	[NamePrefix] [varchar](50) NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NULL,
	[CareOff] [varchar](50) NULL,
	[CareOffCode] [int] NULL,
	[CompanyId] [int] NULL,
	[PatientCategoryId] [int] NOT NULL,
	[PatientWard] [int] NULL,
	[RoomNo] [varchar](50) NOT NULL,
	[ConsultantId] [bigint] NOT NULL,
	[Status] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NULL,
 CONSTRAINT [PK_PATIENT] PRIMARY KEY CLUSTERED 
(
	[EntryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_PATIENT] UNIQUE NONCLUSTERED 
(
	[PatientIp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnInventoryValuation]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPTnInventoryValuation](
	[InventoryValuationId] [bigint] IDENTITY(1,1) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[MinValuation] [money] NOT NULL,
	[MaxValuation] [money] NOT NULL,
	[AvgValuation] [money] NOT NULL,
	[CurrentValuation] [money] NOT NULL,
	[DataDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_InventoryValuationId] PRIMARY KEY CLUSTERED 
(
	[InventoryValuationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPTnIssuance_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnIssuance_D](
	[IssuanceDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[IssuanceId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[IndentId] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[DemandQty] [int] NOT NULL,
	[IssuedQty] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_IssuanceDetailId] PRIMARY KEY CLUSTERED 
(
	[IssuanceDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnIssuance_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnIssuance_M](
	[IssuanceId] [varchar](50) NOT NULL,
	[IssuanceDate] [datetime] NOT NULL,
	[WarehouseId] [bigint] NOT NULL,
	[DepartmentId] [int] NOT NULL,
	[IndentId] [varchar](50) NOT NULL,
	[Status] [nchar](10) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_IssuanceId] PRIMARY KEY CLUSTERED 
(
	[IssuanceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnItemDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnItemDiscard_D](
	[ItemDiscardDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemDiscardId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[BatchNo] [varchar](50) NULL,
	[ExpiryDate] [datetime] NULL,
	[ItemRate] [money] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[DiscardReasonIdId] [bigint] NULL,
	[Amount] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ItemDiscardDetailId] PRIMARY KEY CLUSTERED 
(
	[ItemDiscardDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnItemDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnItemDiscard_M](
	[ItemDiscardId] [varchar](50) NOT NULL,
	[ItemDiscardDate] [datetime] NOT NULL,
	[ItemTypeId] [int] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[DIscardType] [int] NOT NULL,
	[IsApprove] [bit] NULL,
	[IsReject] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ItemDiscardId] PRIMARY KEY CLUSTERED 
(
	[ItemDiscardId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnOnHoldItem]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnOnHoldItem](
	[OnHoldId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[OnHold] [bit] NOT NULL,
	[OnHoldDate] [datetime] NOT NULL,
	[UnHoldDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_OnHoldId] PRIMARY KEY CLUSTERED 
(
	[OnHoldId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnOPDPatient]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SCPTnOPDPatient](
	[DataEntryID] [bigint] IDENTITY(1,1) NOT NULL,
	[ConsultantId] [int] NOT NULL,
	[PatientCount] [int] NOT NULL,
	[DataDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_OPDPatient] PRIMARY KEY CLUSTERED 
(
	[DataEntryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SCPTnPharmacyIssuance_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPharmacyIssuance_D](
	[PharmacyIssuanceDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[PharmacyIssuanceId] [varchar](50) NOT NULL,
	[DemandId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[ItemBalance] [int] NOT NULL,
	[DemandQty] [int] NOT NULL,
	[IssueQty] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PharmacyIssuanceDetailId] PRIMARY KEY CLUSTERED 
(
	[PharmacyIssuanceDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPharmacyIssuance_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPharmacyIssuance_M](
	[PharmacyIssuanceId] [varchar](50) NOT NULL,
	[PharmacyIssuanceDate] [datetime] NOT NULL,
	[FromWarehouseId] [bigint] NOT NULL,
	[ToWarehouseId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PharmacyIssuanceId] PRIMARY KEY CLUSTERED 
(
	[PharmacyIssuanceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPharmacyReceiving_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPharmacyReceiving_D](
	[PharmacyReceivingDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[PharmacyReceivingId] [varchar](50) NOT NULL,
	[DemandId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[ItemBalance] [int] NOT NULL,
	[DemandQty] [int] NOT NULL,
	[RecievedQty] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PharmacyReceivingDetailId] PRIMARY KEY CLUSTERED 
(
	[PharmacyReceivingDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPharmacyReceiving_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPharmacyReceiving_M](
	[PharmacyReceivingId] [varchar](50) NOT NULL,
	[PharmacyReceivingDate] [datetime] NOT NULL,
	[FromWarehouseId] [bigint] NULL,
	[ToWarehouseId] [bigint] NULL,
	[PharmacyIssuanceId] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PharmacyReceivingId] PRIMARY KEY CLUSTERED 
(
	[PharmacyReceivingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseOrder_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseOrder_D](
	[PurchaseOrderDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[PurchaseOrderId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[PurchaseRequisitionId] [varchar](50) NULL,
	[RequestedQty] [int] NOT NULL,
	[OrderQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[ItemRate] [money] NOT NULL,
	[NetAmount] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[BonusQty] [int] NULL,
 CONSTRAINT [PK_PuchaseOrderDetailId] PRIMARY KEY CLUSTERED 
(
	[PurchaseOrderDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseOrder_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseOrder_M](
	[PurchaseOrderId] [varchar](50) NOT NULL,
	[PurchaseOrderDate] [datetime] NOT NULL,
	[SupplierId] [bigint] NOT NULL,
	[WarehouseId] [bigint] NOT NULL,
	[ItemRate] [char](2) NOT NULL,
	[TotalAmount] [money] NOT NULL,
	[PrintDate] [datetime] NULL,
	[IsApprove] [bit] NULL,
	[IsReject] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PuchaseOrderId] PRIMARY KEY CLUSTERED 
(
	[PurchaseOrderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseOrderDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseOrderDiscard_D](
	[PurchaseOrderDiscardDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[PurchaseOrderDiscardId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[OrderQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[RemainingQty] [int] NOT NULL,
	[DiscardReasonIdId] [bigint] NOT NULL,
	[DiscardReasonId] [varchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PuchaseOrderDiscardDetailId] PRIMARY KEY CLUSTERED 
(
	[PurchaseOrderDiscardDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseOrderDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseOrderDiscard_M](
	[PurchaseOrderDiscardId] [varchar](50) NOT NULL,
	[PurchaseOrderDiscardDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[SupplierId] [bigint] NOT NULL,
	[PurchaseOrderId] [varchar](50) NOT NULL,
	[IsApprove] [bit] NULL,
	[IsReject] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PuchaseOrderDiscardId] PRIMARY KEY CLUSTERED 
(
	[PurchaseOrderDiscardId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseRequisition_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseRequisition_D](
	[PurchaseRequisitionDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[PurchaseRequisitionId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[MinLevel] [int] NOT NULL,
	[MaxLevel] [int] NOT NULL,
	[RequestedQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[ReasonId] [bigint] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PuchaseRequisitionDetailId] PRIMARY KEY CLUSTERED 
(
	[PurchaseRequisitionDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseRequisition_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseRequisition_M](
	[PurchaseRequisitionId] [varchar](50) NOT NULL,
	[PurchaseRequisitionDate] [datetime] NOT NULL,
	[ProcurementType] [varchar](50) NOT NULL,
	[WraehouseId] [int] NOT NULL,
	[ProcurementId] [int] NOT NULL,
	[Priority] [char](2) NOT NULL,
	[IsApprove] [bit] NULL,
	[IsReject] [bit] NULL,
	[PrintDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_PuchaseRequisitionId] PRIMARY KEY CLUSTERED 
(
	[PurchaseRequisitionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseRequisitionDiscard_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseRequisitionDiscard_D](
	[RequisitionDiscardDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[RequisitionDiscardId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[RequestedQty] [int] NOT NULL,
	[PendingQty] [int] NOT NULL,
	[DiscardQty] [int] NOT NULL,
	[RemainingQty] [int] NOT NULL,
	[DiscardReasonId] [bigint] NOT NULL,
	[DiscardReason] [varchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_RequisitionDiscardDetailId] PRIMARY KEY CLUSTERED 
(
	[RequisitionDiscardDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnPurchaseRequisitionDiscard_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnPurchaseRequisitionDiscard_M](
	[RequisitionDiscardId] [varchar](50) NOT NULL,
	[RequisitionDiscardDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[PurchaseRequisitionId] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_RequisitionDiscardId] PRIMARY KEY CLUSTERED 
(
	[RequisitionDiscardId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnRateSlab]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnRateSlab](
	[RateChangeSlabId] [bigint] IDENTITY(1,1) NOT NULL,
	[GoodReceiptDetailId] [bigint] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[RateChangViewed] [bit] NULL,
	[Ratechanged] [bit] NULL,
	[RateChangeId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_RateChangeSlabId] PRIMARY KEY CLUSTERED 
(
	[RateChangeSlabId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnReturnToStore_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnReturnToStore_D](
	[ReturnToStoreDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[ReturnToStoreId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[ItemBalance] [int] NOT NULL,
	[ReturnQty] [int] NOT NULL,
	[ReturnReasonIdId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ReturnToStoreDetailId] PRIMARY KEY CLUSTERED 
(
	[ReturnToStoreDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnReturnToStore_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnReturnToStore_M](
	[ReturnToStoreId] [varchar](50) NOT NULL,
	[ReturnToStoreDate] [datetime] NOT NULL,
	[FromWarehouseId] [bigint] NOT NULL,
	[ToWarehouseId] [bigint] NOT NULL,
	[IsApprove] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_ReturnToStoreId] PRIMARY KEY CLUSTERED 
(
	[ReturnToStoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnReturnToSupplier_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnReturnToSupplier_D](
	[ReturnToSupplierDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[ReturnToSupplierId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[ItemRate] [money] NOT NULL,
	[ReturnQty] [int] NOT NULL,
	[NetAmount] [money] NOT NULL,
	[ReturnReasonIdId] [int] NOT NULL,
	[SettlementStatus] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[CREDIT_NOTE_NO] [varchar](50) NULL,
 CONSTRAINT [PK_ReturnToSupplierDetailId] PRIMARY KEY CLUSTERED 
(
	[ReturnToSupplierDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnReturnToSupplier_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnReturnToSupplier_M](
	[ReturnToSupplierId] [varchar](50) NOT NULL,
	[ReturnToSupplierDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[DatePassCode] [varchar](50) NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[SupplierId] [bigint] NOT NULL,
 CONSTRAINT [PK_ReturnToSupplierId] PRIMARY KEY CLUSTERED 
(
	[ReturnToSupplierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnSale_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnSale_D](
	[SaleDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[SaleId] [varchar](50) NOT NULL,
	[Pneumonics] [varchar](max) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[CurrentStock] [bigint] NOT NULL,
	[DoseId] [bigint] NOT NULL,
	[SignaId] [varchar](50) NOT NULL,
	[Duration] [bigint] NOT NULL,
	[ItemRate] [money] NOT NULL,
	[PaymentTermId] [bigint] NOT NULL,
	[Quantity] [bigint] NOT NULL,
	[Amount] [money] NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SaleDetailId] PRIMARY KEY CLUSTERED 
(
	[SaleDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnSale_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnSale_M](
	[SaleId] [varchar](50) NOT NULL,
	[SaleDate] [datetime] NOT NULL,
	[PatientCategoryId] [bigint] NOT NULL,
	[PatientSubCategoryId] [bigint] NOT NULL,
	[PatientIp] [varchar](50) NOT NULL,
	[PatientRegistrationNo] [varchar](50) NULL,
	[DifferenceTime] [datetime] NULL,
	[NamePrefix] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[PatientTypeId] [bigint] NOT NULL,
	[CompanyId] [bigint] NOT NULL,
	[ConsultantId] [bigint] NOT NULL,
	[CareOff] [varchar](50) NOT NULL,
	[CareOffCode] [int] NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivedAmount] [money] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[PrintDate] [datetime] NULL,
 CONSTRAINT [PK_SaleId] PRIMARY KEY CLUSTERED 
(
	[SaleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnSaleRefund_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnSaleRefund_D](
	[SaleRefundDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[SaleRefundId] [varchar](50) NOT NULL,
	[PaymentTermId] [bigint] NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[BatchNo] [varchar](50) NULL,
	[ItemRate] [money] NOT NULL,
	[ItemPackingQuantity] [int] NOT NULL,
	[SaleAmount] [money] NOT NULL,
	[ReturnQty] [int] NOT NULL,
	[ReturnAmount] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SaleRefundDetailId] PRIMARY KEY CLUSTERED 
(
	[SaleRefundDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnSaleRefund_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnSaleRefund_M](
	[SaleRefundId] [varchar](50) NOT NULL,
	[SaleRefundDate] [datetime] NOT NULL,
	[PatinetIp] [varchar](50) NULL,
	[SaleId] [varchar](50) NULL,
	[BatchNo] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_SaleRefundId] PRIMARY KEY CLUSTERED 
(
	[SaleRefundId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnStock_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnStock_D](
	[StockDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[TransactionDocumentName] [varchar](50) NOT NULL,
	[TransactionDocumentId] [varchar](50) NOT NULL,
	[OpeningStock] [bigint] NOT NULL,
	[TransactionType] [varchar](50) NOT NULL,
	[StockQuantity] [int] NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[ItemBalance] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_StockDetailId] PRIMARY KEY CLUSTERED 
(
	[StockDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnStock_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnStock_M](
	[StockId] [int] IDENTITY(1000,1) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[BatchNo] [varchar](50) NOT NULL,
	[CurrentStock] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_StockId] PRIMARY KEY CLUSTERED 
(
	[StockId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnStockTaking_D]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnStockTaking_D](
	[StockTakingDetailId] [bigint] IDENTITY(1,1) NOT NULL,
	[StockTakingId] [varchar](50) NOT NULL,
	[ItemCode] [varchar](50) NOT NULL,
	[ItemRate] [money] NOT NULL,
	[BatchNo] [varchar](50) NULL,
	[CurrentStock] [int] NOT NULL,
	[PhysicalStock] [int] NOT NULL,
	[ShortQty] [int] NOT NULL,
	[ExcessQty] [int] NOT NULL,
	[ShortAmount] [money] NOT NULL,
	[ExcessAmount] [money] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_StockTakingDetailId] PRIMARY KEY CLUSTERED 
(
	[StockTakingDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnStockTaking_M]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnStockTaking_M](
	[StockTakingId] [varchar](50) NOT NULL,
	[StockTakingDate] [datetime] NOT NULL,
	[WraehouseId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_StockTakingId] PRIMARY KEY CLUSTERED 
(
	[StockTakingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SCPTnUserLog]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SCPTnUserLog](
	[UserLogId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [bigint] NOT NULL,
	[Description] [varchar](50) NULL,
	[TransactionDocumentName] [varchar](50) NOT NULL,
	[TransactionDocumentId] [varchar](50) NULL,
	[FormCode] [varchar](50) NOT NULL,
	[IpAddress] [varchar](50) NULL,
	[IsActive] [bit] NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[EditedBy] [int] NULL,
	[EditedDate] [datetime] NULL,
	[RowStamp] [timestamp] NOT NULL,
	[Activity] [varchar](50) NULL,
 CONSTRAINT [PK_UserLog] PRIMARY KEY CLUSTERED 
(
	[UserLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[Vw_SCPCurrentItemPrice]    Script Date: 02/Feb/2020 11:32:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Vw_SCPCurrentItemPrice]
AS

SELECT ItemCode,
		FromDate, 
		ToDate, 
		SalePrice, 
		CostPrice
FROM [dbo].[SCPStRate]
WHERE CAST(GETDATE() as date) BETWEEN
			CAST(CONVERT(date,FromDate,103) as date) AND 
			CAST(CONVERT(date,ToDate,103) as date) 




GO
USE [master]
GO
ALTER DATABASE [ICHIMS] SET  READ_WRITE 
GO
