# Data structure

This document lays out the data structure of the various files and tables used by the repo.

## Safety Culture

The relevant tables and fields from Safety Culture are as follows, showing the fields in the table, what they mean, and what this tooling uses them for (if anything). Full documentation is provided [on the Safety Culture website](https://developer.safetyculture.com/docs/understanding-the-data)

### Templates

This table is exported into the database table `templates`.

| Field name      | Meaning | Used for |
|-----------------|---------|----------|
| template_id     | Unique ID | Linking tables |
| archived        | Whether archived | Ignored - we still care about data from templates that are no longer in use  |
| name            | Template name | Filtering which templates we care about |
| description     |         |          |
| organisation_id |         |          |
| owner_name      |         |          |
| owner_id        |         |          |
| author_name     |         |          |
| author_id       |         |          |
| created_at      |         |          |
| modified_at     |         |          |
| exported_at     |         |          |

### Inspections

This table is exported into the database table `inspections`.

| Field name            | Meaning   | Used for  |
|-----------------------|-----------|-----------|
| audit_id              | Unique ID | Linking tables  |
| name                  | Creator   | - |
| archived              | Whether archived  | Ignored (though archived inspections are still used) |
| owner_name            |   | -  |
| owner_id              |   |   |
| author_name           |   |   |
| author_id             |   |   |
| score                 |   |   |
| max_score             |   |   |
| score_percentage      |   |   |
| duration              |   |   |
| template_id           | ID of template  | Ignored (we use the template name instead) |
| organisation_id       |   |   |
| template_name         | Name of template  | ??? |
| template_author       |   |   |
| site_id               |   |   |
| date_started          | Date started | - |
| date_completed        | Date completed | - |
| date_modified         | Date modified  | - |
| created_at            |   |   |
| modified_at           |   |   |
| exported_at           |   |   |
| document_no           |   |   |
| prepared_by           |   |   |
| location              |   |   |
| conducted_on          | Date and time of inspection | Date and time of inspection |
| personnel             |   |   |
| client_site           |   |   |
| latitude              |   |   |
| longitude             |   |   |
| web_report_link       |   |   |
| deleted               |   |   |
| asset_id              |   |   |

### Inspection items

This table is exported into the database table `inspection_items`. Each item in this table is some part of the filled out inspection form, such as a question or response.

This is post processed to extract the relevant information by selecting on the following.

- `audit_id` - links to the inspection.

- `type` - we only care about answers to questions.

- `item_id` - which question this is. For example, the question "Was alcohol consumed" will have a particular unique `item_id` value for each template it appears in.

- `item_index` - numerical identifier for the item in the context of the inspection.

- `label` - what the question actually was.

- `response` - what the answer was (normally the data we care about).

| Field name               | Meaning | Used for |
|--------------------------|---------|----------|
| id                       | Combination of item_id and audit_id for some reason | -   |
| item_id                  | ID of this item | -  |
| audit_id                 | Inspection unique ID | Linking tables  |
| item_index               | ???     |          |
| template_id              | Template ID | Ignored - this is in the inspection too   |
| parent_id                | Hierarchy | ???      |
| created_at               |         |          |
| modified_at              |         |          |
| exported_at              |         |          |
| type                     | Type of item (such as checkbox, question, or list)   |          |
| category                 | Location in form  |          |
| category_id              |         |          |
| organisation_id          |         |          |
| parent_ids               |         |          |
| label                    | Identifier (such as question wording)  |          |
| response                 | Response given | Data for output         |
| response_id              |         |          |
| response_set_id          |         |          |
| is_failed_response       |         |          |
| comment                  |         |          |
| media_files              |         |          |
| media_ids                |         |          |
| media_hypertext_reference|         |          |
| score                    |         |          |
| max_score                |         |          |
| score_percentage         |         |          |
| combined_score           |         |          |
| combined_max_score       |         |          |
| combined_score_percentage|         |          |
| mandatory                |         |          |
| inactive                 |         |          |
| location_latitude        |         |          |
| location_longitude       |         |          |
| primeelement_id          |         |          |
| primeelement_index       |         |          |

## Power BI imports

The key tables used by Power BI are the following.

### All SUF data table

*Work in progress - will remove and point at view definitions once they are complete*

~~~
All_Digital_SUF_Weekday
All_Digital_SUF_form_id
All_Digital_SUF_job_creation_datetime
All_Digital_SUF_job_creation_date
All_Digital_SUF_job_creation_time
All_Digital_SUF_Alcohol
All_Digital_SUF_Drugs
All_Digital_SUF_Phone_Charge
All_Digital_SUF_Distressed
All_Digital_SUF_Lost_Friends
All_Digital_SUF_Mental_Health
All_Digital_SUF_Getting_Home
All_Digital_SUF_Friendly_Ear
All_Digital_SUF_First_Aid
All_Digital_SUF_Assault
All_Digital_SUF_Sexual
All_Digital_SUF_Hate_Crime
All_Digital_SUF_Domestic_Abu_Ass
All_Digital_SUF_Other
All_Digital_SUF_venue_name
All_Digital_SUF_venue_name_other
All_Digital_SUF_has_the_client_sustained_any_injuries
All_Digital_SUF_does_the_client_require_observations
All_Digital_SUF_found_alone
All_Digital_SUF_type_of_involvement
All_Digital_SUF_client_provisions
All_Digital_SUF_Contact_Family
All_Digital_SUF_Contact_Friend
All_Digital_SUF_Emotional_Support
All_Digital_SUF_First_Aid2
All_Digital_SUF_Phone_Charge3
All_Digital_SUF_Water_Tea
All_Digital_SUF_Advice
All_Digital_SUF_Safe_Route_Home
All_Digital_SUF_Shelter
All_Digital_SUF_Other4
All_Digital_SUF_Calcd_TreatmentTime_Mins_
All_Digital_SUF_Lost
All_Digital_SUF_Status_Column
All_Digital_SUF_Column239
All_Digital_SUF_Column240
All_Digital_SUF_Column241
All_Digital_SUF_Column242
All_Digital_SUF_Column243
~~~

## Database tables

### Exported data tables

The tables `inspections` and `inspection_items` contain data directly exported from Safety Culture.

### Timing table

The table `dbo.JobTimestamp` contains a single timestamp, containing the last time an export was run successfully. It is read before each run, and updated afterwards on success.

This is because the Safety Culture exporter needs to be passed it in order to only download changes since the last time. If this table is dropped, then a full resync will be done.

### Views

*xxx write docs of the views*
