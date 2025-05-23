-- sqlcmd -b -S ${SERVER} -d ${DB} -U ${ADMINUSER} -P ${ADMINPWD} -i create_powerbi_nightly.sql
-- Create the nightly_data table
PRINT("Create nightly_data");
DROP TABLE IF EXISTS dbo.nightly_data;
GO
CREATE TABLE dbo.nightly_data (
    service_date DATE NOT NULL PRIMARY KEY, -- service_date
    Date_Report_Format_ DATE NOT NULL, -- service_date formatted for report
    Delivery_Nights INT, -- Each night is one night; quite why this is needed is unclear
    Delivery_Hours INT, -- Assumed 7 hours per night; some legacy data uses different values
    Volunteers_Total INT, -- How many volunteers were on that night
    Volunteer_Hours INT, -- Hours that night, based on 7 delivery hours
    Real_Living_Wage_ DECIMAL(10,2), -- Cost of those hours at 8.75 real living wage
    National_LivingWage_ DECIMAL(10,2), -- Cost of those hours at 7.50 national living wage
    Patients_Treated INT, -- Number of inspections identified
    DATA_SROI_ DECIMAL(10,2), -- Value, assuming £850 per person engaged with
    Treatment_Time_Mins_ INT, -- Total time spent on inspections
    CB_Overall DECIMAL(10,2), -- Cost Benefit - SROI minus real living wage cost
    CB_per_volunteer DECIMAL(10,2), -- Cost Benefit per volunteer
    -- Observations performed
    Obs INT,
    -- gender
    Male INT,
    Female INT,
    -- Since this is no longer a valid answer to the question (which explicitly allows "Male (including transgender men)"), not going to include
    TG INT,
    GenderOther INT, -- My addition
    GenderNull INT, -- My addition
    -- Counts if found alone
    -- TODO: horrible names, as uninformative
    Yes INT,
    No INT,
    -- ignoring LIVE_REPORT_DATA_TG_1 as never set
    Male_Alone INT,
    Female_Alone INT,
    TG_Alone INT,
    -- age_range
    -- TODO: horrible names for SQL, so should clean up, but needs PowerBI changes too
    Under_16 INT,
    [17-18] INT,
    [19-24] INT,
    [25-34] INT,
    [35-45] INT,
    [46] INT,
    Age_Unknown INT,
    -- residency
    Local INT,
    Student INT,
    Tourist_Holiday INT,
    Visiting INT,
    Homeless INT,
    -- where_do_they_study
    EDI_Uni INT,
    HW_Uni INT,
    QMU INT,
    Napier INT,
    -- Data expects this INT, even though no examples
    EDI_College INT,
    Academic_Other INT,
    -- referred_by
    General_Public INT,
    Street_Pastor INT,
    Street_Assist INT,
    Partner_Friend INT,
    -- This can match either "Police" or "Transport Police" INT, but we bundle together anyway
    Police_BTP INT,
    Pub_Club INT,
    Self_Refer INT,
    Taxi_Marshall INT,
    Ambulance INT,
    Lothian_Buses INT,
    Com_Safety INT,
    CCTV_Control INT,
    Referred_Other INT,
    -- job_category
    Alcohol INT,
    Drugs INT,
    Phone_Charge INT,
    Distressed INT,
    -- TODO: Seems odd that we have both "Lost" and "Lost Friends"
    Lost INT,
    Lost_Friends INT,
    Mental_Health INT,
    Getting_Home INT,
    Friendly_Ear INT,
    First_Aid INT,
    Assault INT,
    Sexual_Assault INT,
    Hate_Crime INT,
    Domestic_Abu_Ass INT,
    Condition_Other INT,
    -- job_outcome
    Left_on_Own INT,
    Left_on_Own_Taxi INT, -- left on own plus taxi home
    Home_by_SA INT,
    Home_by_Family INT,
    Home_by_Friend INT,
    Phone_Charged INT,
    Refused_Treat INT,
    SAS_to_ERI INT,
    SA_to_ERI INT,
    REH INT,
    Police_Care INT,
    Taxi_Home INT,
    Taxi_to_ERI INT,
    Stood_Down INT,
    Arrested INT,
    -- client_provisions
    First_Aid_2 INT,
    Phone_Charge_3 INT,
    Safe_Route_Home INT,
    Contact_Family INT,
    Contact_Friend INT,
    Emotional_Support INT,
    Advice INT,
    Shelter INT,
    Water_Tea INT,
    Provision_Other INT
);
GO

-- Copy in the view data
PRINT("Copy view data into nightly_data");
INSERT INTO dbo.nightly_data
(
    service_date,
    Date_Report_Format_,
    Delivery_Nights,
    Delivery_Hours,
    Volunteers_Total,
    Volunteer_Hours,
    Real_Living_Wage_,
    National_LivingWage_,
    Patients_Treated,
    DATA_SROI_,
    Treatment_Time_Mins_,
    CB_Overall,
    CB_per_volunteer,
    -- Observations performed
    Obs,
    -- gender
    Male,
    Female,
    TG,
    GenderOther,
    GenderNull,
    Yes,
    No,
    Male_Alone,
    Female_Alone,
    TG_Alone,
    -- age_range
    -- TODO: horrible names for SQL, so should clean up, but needs PowerBI changes too
    Under_16,
    [17-18],
    [19-24],
    [25-34],
    [35-45],
    [46],
    Age_Unknown,
    -- residency
    Local,
    Student,
    Tourist_Holiday,
    Visiting,
    Homeless,
    -- where_do_they_study
    EDI_Uni,
    HW_Uni,
    QMU,
    Napier,
    EDI_College,
    Academic_Other,
    -- referred_by
    General_Public,
    Street_Pastor,
    Street_Assist,
    Partner_Friend,
    Police_BTP,
    Pub_Club,
    Self_Refer,
    Taxi_Marshall,
    Ambulance,
    Lothian_Buses,
    Com_Safety,
    CCTV_Control,
    Referred_Other,
    -- job_category
    Alcohol,
    Drugs,
    Phone_Charge,
    Distressed,
    Lost,
    Lost_Friends,
    Mental_Health,
    Getting_Home,
    Friendly_Ear,
    First_Aid,
    Assault,
    Sexual_Assault,
    Hate_Crime,
    Domestic_Abu_Ass,
    Condition_Other,
    -- job_outcome
    Left_on_Own,
    Left_on_Own_Taxi,
    Home_by_SA,
    Home_by_Family,
    Home_by_Friend,
    Phone_Charged,
    Refused_Treat,
    SAS_to_ERI,
    SA_to_ERI,
    REH,
    Police_Care,
    Taxi_Home,
    Taxi_to_ERI,
    Stood_Down,
    Arrested,
    First_Aid_2,
    Phone_Charge_3,
    Safe_Route_Home,
    Contact_Family,
    Contact_Friend,
    Emotional_Support,
    Advice,
    Shelter,
    Water_Tea,
    Provision_Other
)
SELECT
    service_date AS service_date,
    service_date AS Date_Report_Format_,
    1 AS Delivery_Nights,
    7 AS Delivery_Hours,
    Volunteers_Total,
    Volunteer_Hours AS Volunteer_Hours,
    Volunteer_Hours * 8.75 AS Real_Living_Wage_,
    Volunteer_Hours * 7.50 AS National_LivingWage_,
    Patients_Treated AS Patients_Treated,
    850 * Patients_Treated AS DATA_SROI_,
    Treatment_Time_Mins_ AS Treatment_Time_Mins_,
    CB_Overall AS CB_Overall,
    CB_per_volunteer AS CB_per_volunteer,
    -- Observations performed
    Obs AS Obs,
    -- gender
    Male AS Male,
    Female AS Female,
    TG AS TG,
    GenderOther AS GenderOther,
    GenderNull AS GenderNull,
    found_alone_yes AS Yes,
    found_alone_no AS No,
    Male_Alone AS Male_Alone,
    Female_Alone AS Female_Alone,
    TG_Alone AS TG_Alone,
    -- age_range
    -- TODO: horrible names for SQL AS SQL, so should clean up, but needs PowerBI changes too
    age_under_16 AS Under_16,
    age_17_18 AS [17-18],
    age_19_24 AS [19-24],
    age_25_34 AS [25-34],
    age_35_45 AS [35_45],
    age_46_plus AS [46],
    age_unknown AS Age_Unknown,
    -- residency
    Local AS Local,
    Student AS Student,
    Tourist_Holiday AS Tourist_Holiday,
    Visiting AS Visiting,
    Homeless AS Homeless,
    -- where_do_they_study
    EDI_Uni AS EDI_Uni,
    HW_Uni AS HW_Uni,
    QMU AS QMU,
    Napier AS Napier,
    0 AS EDI_College, -- no such data
    Academic_Other AS Academic_Other,
    -- referred_by
    General_Public AS General_Public,
    Street_Pastor AS Street_Pastor,
    Street_Assist AS Street_Assist,
    Partner_Friend AS Partner_Friend,
    Police_BTP AS Police_BTP,
    Pub_Club AS Pub_Club,
    Self_Refer AS Self_Refer,
    Taxi_Marshall AS Taxi_Marshall,
    Ambulance AS Ambulance,
    Lothian_Buses AS Lothian_Buses,
    Com_Safety AS Com_Safety,
    CCTV_Control AS CCTV_Control,
    Referred_Other AS Referred_Other,
    -- job_category
    Alcohol AS Alcohol,
    Drugs AS Drugs,
    Phone_Charge AS Phone_Charge,
    Distressed AS Distressed,
    0 AS Lost, -- No longer an option, but used to be
    Lost_Friends AS Lost_Friends,
    Mental_Health AS Mental_Health,
    Getting_Home AS Getting_Home,
    Friendly_Ear AS Friendly_Ear,
    First_Aid AS First_Aid,
    Assault AS Assault,
    Sexual_Assault AS Sexual_Assault,
    Hate_Crime AS Hate_Crime,
    Domestic_Abu_Ass AS Domestic_Abu_Ass,
    Condition_Other AS Condition_Other,
    -- job_outcome
    Left_on_Own AS Left_on_Own,
    Left_on_Own_Taxi AS Left_on_Own_Taxi,
    Home_by_SA AS Home_by_SA,
    Home_by_Family AS Home_by_Family,
    Home_by_Friend AS Home_by_Friend,
    Phone_Charged AS Phone_Charged,
    Refused_Treat AS Refused_Treat,
    SAS_to_ERI AS SAS_to_ERI,
    SA_to_ERI AS SA_to_ERI,
    REH AS REH,
    Police_Care AS Police_Care,
    Taxi_Home AS Taxi_Home,
    Taxi_to_ERI AS Taxi_to_ERI,
    Stood_Down AS Stood_Down,
    Arrested AS Arrested,
    First_Aid_2 AS First_Aid_2,
    Phone_Charge_3 AS Phone_Charge_3,
    Safe_Route_Home AS Safe_Route_Home,
    Contact_Family AS Contact_Family,
    Contact_Friend AS Contact_Friend,
    Emotional_Support AS Emotional_Support,
    Advice AS Advice,
    Shelter AS Shelter,
    Water_Tea AS Water_Tea,
    Provision_Other AS Provision_Other
FROM nightly_view
WHERE service_date >= '2024-01-01';
GO

-- Copy in the historic nightly data
PRINT("Copy historic data into nightly_data");
INSERT INTO dbo.nightly_data
(
    service_date,
    Date_Report_Format_,
    Delivery_Nights,
    Delivery_Hours,
    Volunteers_Total,
    Volunteer_Hours,
    Real_Living_Wage_,
    National_LivingWage_,
    Patients_Treated,
    DATA_SROI_,
    Treatment_Time_Mins_,
    CB_Overall,
    CB_per_volunteer,
    -- Observations performed
    Obs,
    -- gender
    Male,
    Female,
    TG,
    GenderOther,
    GenderNull,
    Yes,
    No,
    Male_Alone,
    Female_Alone,
    TG_Alone,
    -- age_range
    -- TODO: horrible names for SQL, so should clean up, but needs PowerBI changes too
    Under_16,
    [17-18],
    [19-24],
    [25-34],
    [35-45],
    [46],
    Age_Unknown,
    -- residency
    Local,
    Student,
    Tourist_Holiday,
    Visiting,
    Homeless,
    -- where_do_they_study
    EDI_Uni,
    HW_Uni,
    QMU,
    Napier,
    EDI_College,
    Academic_Other,
    -- referred_by
    General_Public,
    Street_Pastor,
    Street_Assist,
    Partner_Friend,
    Police_BTP,
    Pub_Club,
    Self_Refer,
    Taxi_Marshall,
    Ambulance,
    Lothian_Buses,
    Com_Safety,
    CCTV_Control,
    Referred_Other,
    -- job_category
    Alcohol,
    Drugs,
    Phone_Charge,
    Distressed,
    Lost,
    Lost_Friends,
    Mental_Health,
    Getting_Home,
    Friendly_Ear,
    First_Aid,
    Assault,
    Sexual_Assault,
    Hate_Crime,
    Domestic_Abu_Ass,
    Condition_Other,
    -- job_outcome
    Left_on_Own,
    Left_on_Own_Taxi,
    Home_by_SA,
    Home_by_Family,
    Home_by_Friend,
    Phone_Charged,
    Refused_Treat,
    SAS_to_ERI,
    SA_to_ERI,
    REH,
    Police_Care,
    Taxi_Home,
    Taxi_to_ERI,
    Stood_Down,
    Arrested,
    First_Aid_2,
    Phone_Charge_3,
    Safe_Route_Home,
    Contact_Family,
    Contact_Friend,
    Emotional_Support,
    Advice,
    Shelter,
    Water_Tea,
    Provision_Other
)
SELECT
    service_date AS service_date,
    service_date AS Date_Report_Format_,
    1 AS Delivery_Nights,
    7 AS Delivery_Hours,
    Volunteers_Total,
    Volunteer_Hours AS Volunteer_Hours,
    Volunteer_Hours * 8.75 AS Real_Living_Wage_, -- Cost of those hours at 8.75
    Volunteer_Hours * 7.50 AS National_LivingWage_, -- Cost of those hours at 7.50
    Patients_Treated AS Patients_Treated,
    Patients_Treated * 850.0 AS DATA_SROI_, -- SROI is 850 per patient
    Treatment_Time_Mins_ AS Treatment_Time_Mins_,
    Patients_Treated * 850.0 - Volunteer_Hours * 8.75 AS CB_Overall, -- Cost Benefit - SROI minus real living wage cost
    CASE
        WHEN Volunteers_Total IS NULL OR Volunteers_Total = 0 THEN 0
        ELSE (Patients_Treated * 850.0 - Volunteer_Hours * 8.75) / Volunteers_Total
    END AS CB_per_volunteer,
    -- Observations performed
    Obs AS Obs,
    -- gender
    Male AS Male,
    Female AS Female,
    TG AS TG,
    GenderOther AS GenderOther,
    GenderNull AS GenderNull,
    found_alone_yes AS Yes,
    found_alone_no AS No,
    Male_Alone AS Male_Alone,
    Female_Alone AS Female_Alone,
    TG_Alone AS TG_Alone,
    -- age_range
    -- TODO: horrible names for SQL AS SQL, so should clean up AS up, but needs PowerBI changes too
    age_under_16 AS Under_16,
    age_17_18 AS [17-18],
    age_19_24 AS [19-24],
    age_25_34 AS [25-34],
    age_35_45 AS [35_45],
    age_46_plus AS [46],
    age_unknown AS Age_Unknown,
    -- residency
    Local AS Local,
    Student AS Student,
    Tourist_Holiday AS Tourist_Holiday,
    Visiting AS Visiting,
    Homeless AS Homeless,
    -- where_do_they_study
    EDI_Uni AS EDI_Uni,
    HW_Uni AS HW_Uni,
    QMU AS QMU,
    Napier AS Napier,
    0 AS EDI_College, -- no such data
    Academic_Other AS Academic_Other,
    -- referred_by
    General_Public AS General_Public,
    Street_Pastor AS Street_Pastor,
    Street_Assist AS Street_Assist,
    Partner_Friend AS Partner_Friend,
    Police_BTP AS Police_BTP,
    Pub_Club AS Pub_Club,
    Self_Refer AS Self_Refer,
    Taxi_Marshall AS Taxi_Marshall,
    Ambulance AS Ambulance,
    Lothian_Buses AS Lothian_Buses,
    Com_Safety AS Com_Safety,
    CCTV_Control AS CCTV_Control,
    Referred_Other AS Referred_Other,
    -- job_category
    Alcohol AS Alcohol,
    Drugs AS Drugs,
    Phone_Charge AS Phone_Charge,
    Distressed AS Distressed,
    Lost AS Lost,
    Lost_Friends AS Lost_Friends,
    Mental_Health AS Mental_Health,
    Getting_Home AS Getting_Home,
    Friendly_Ear AS Friendly_Ear,
    First_Aid AS First_Aid,
    Assault AS Assault,
    Sexual_Assault AS Sexual_Assault,
    Hate_Crime AS Hate_Crime,
    Domestic_Abu_Ass AS Domestic_Abu_Ass,
    Condition_Other AS Condition_Other,
    -- job_outcome
    Left_on_Own AS Left_on_Own,
    Left_on_Own_Taxi AS Left_on_Own_Taxi,
    Home_by_SA AS Home_by_SA,
    Home_by_Family AS Home_by_Family,
    Home_by_Friend AS Home_by_Friend,
    Phone_Charged AS Phone_Charged,
    Refused_Treat AS Refused_Treat,
    SAS_to_ERI AS SAS_to_ERI,
    SA_to_ERI AS SA_to_ERI,
    REH AS REH,
    Police_Care AS Police_Care,
    Taxi_Home AS Taxi_Home,
    Taxi_to_ERI AS Taxi_to_ERI,
    Stood_Down AS Stood_Down,
    Arrested AS Arrested,
    First_Aid_2 AS First_Aid_2,
    Phone_Charge_3 AS Phone_Charge_3,
    Safe_Route_Home AS Safe_Route_Home,
    Contact_Family AS Contact_Family,
    Contact_Friend AS Contact_Friend,
    Emotional_Support AS Emotional_Support,
    Advice AS Advice,
    Shelter AS Shelter,
    Water_Tea AS Water_Tea,
    Provision_Other AS Provision_Other
FROM historic_nightly
WHERE service_date < '2024-01-01';
GO
