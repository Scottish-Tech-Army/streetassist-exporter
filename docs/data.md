# Data structure

This document lays out the data structure of the various files and tables used by the repo.

## Safety Culture tables

The relevant tables and fields from Safety Culture are as follows, showing the fields in the table, what they mean, and what this tooling uses them for (if anything). Full documentation is provided [on the Safety Culture website](https://developer.safetyculture.com/docs/understanding-the-data). Throughout, we include data with the `archived` field set.

### Templates

This table is exported into the database table `templates`. The data was manually used to allow filtering on inspections by `template_id`. Interesting fields include the following.

| Field name      | Meaning | Used for |
|-----------------|---------|----------|
| template_id     | Unique ID | Value extracted to allow filtering of inspections |
| name            | Template name | Figuring out what the template is for |

### Inspections

This table is exported into the database table `inspections`. Interesting fields include the following. The types of inspections we care about (identified by the `template_id` field) are those corresponding to "Sign In" (i.e. a volunteer is signing in, necessary so we can count volunteers each night); "Welfare Check" for welfare checks; and a number of variations on "Service User Form" for general interactions.

| Field name            | Meaning   | Used for  |
|-----------------------|-----------|-----------|
| audit_id              | Unique ID | Linking tables  |
| archived              | Whether archived  | Ignored (though archived inspections are still used) |
| conducted_on          | Date and time of inspection | Date and time of inspection |
| template_id           | ID of template  | Used to filter out which inspections we care about |
| template_name         | Name of template  | Useful to debug things |

Certain fields are added to this table to allow for better indexing and handling of data later. In particular, there is a field `service_date` that is defined by subtracting 12 hours from the `conducted_on` field then converting to a date. This allows interactions on the same night before and after midnight (including signing in of volunteers and interactions with the public) to be connected as the same logical date.

### Inspection items

This table is exported into the database table `inspection_items`. Each item in this table is some part of the filled out inspection form, such as a question or response.

This is post processed to extract the relevant information by selecting on the following.

- `audit_id` - links to the inspection.

- `item_id` - where we are in the form. For example, the question "Was alcohol consumed" will have a particular unique `item_id` value for each template it appears in.

- `type` - in combination with `item_id` this identifies the question. There may be two possible fields with the same `item_id` and different `type` values if, for example, one of them indicates the actual value entered, and the other indicates the start of a new section. We usually care about types of `question` (multiple choice question), `list` (multiple choice question with multiple responses permitted), and `textsingle` (free form text entry).

- `item_index` - numerical identifier for the item in the context of the inspection. If you select on a given `audit_it`, the items are numbered 1 to N using this index.

- `label` - the text of the question which is being asked.

- `response` - what the answer was (normally the data we care about).

Note that the values of questions and their types are specified based on the template as it was when the form was filled out; the wording sometimes evolves.

Interesting fields include the following

| Field name               | Meaning | Used for |
|--------------------------|---------|----------|
| audit_id                 | Inspection unique ID | Linking to the inspection in question  |
| item_id                  | ID of this item | Identifying what this is, in conjunction with type |
| type                     | Type of item  | Identifying what this is, in conjunction with item_id  |
| template_id              | Template ID | Filtering for inspections we care about  |
| label                    | Identifier (such as question wording)  |          |
| response                 | Response given | Data for output         |

### Updates to Safety Culture based tables

After the Safety Culture data is exported, the table data is modified, with the addition of various indices, and the removal of PII.

## Base data tables and views

Once we have the data from Safety Culture, we need to do two thing

- Create data tables for the various historic data that does not come from Safety Culture.

- Turning the Safety Culture into something more useful by combining the inspection items and inspections tables, and interpreting the `item_id` fields to turn some UUID into a meaningful column name.


### Inspection view

The view `inspectionview` contains data about all inspections using the various "Service User Form" templates. It is created by joining the `inspections` and `inspection_items` fields, filtering on `template_id`, and then extracting appropriate fields (based largely on `item_id`) to extract all relevant information about an interaction.

### Welfare Checks

The view `welfarecheckview` contains data about all inspections using the "Welfare Check" template. It is created by joining the `inspections` and `inspection_items` fields, filtering on `template_id`, and then extracting appropriate fields to extract all relevant information about a welfare check.

### Sign in view

The views `signinview` and `signincount` are used to track volunteer signins.

- The view `signinview` extracts the names of each volunteer who signed in on a given night, by selecting from `inspections` where the `template_id` matches the "Sign in" template.

- The view `signincount` converts the sign in data into nightly counts. It also performs some useful calculations used later (converting number of volunteers into equivalent costs at different wage rates, and calculating number of hours worked based on 7 hours per shift).

### Historic data

Various sets of historic data (from before Safety Culture) are loaded from csv files into tables.

- The table `historic_all_suf` contains historic data about all users of the SUF forms.

- The table `historic_welfare_checks` contains historic welfare check data.

- The table `places` is just directly used, but comes from CSV.

## Secondary views

Having built the views, and got the data into a useful format, we go through another stage. For example, the `client_provisions` field (that we extracted from the inspection items table and linked to the inspection in question) is a string of values representing things provided (such as "First Aid" or "Contact Friends") separated by `||`; we want to extract the various valid values to find out what was provided. Hence we parse things further into more detailed views.

These views are as follows.

- The view `all_suf_view` contains the contents of `inspectionview` appropriately filtered and restructured. This map is fairly straightforward, but not totally trivial. For examples, `inspectionview` contains the job outcome (extracted from a field in `inspection_items`) as `job_outcome`, and it is in this view that the outcome values are parsed.

- The view `nightly_view` is a nightly summary. It combines data from `signincount` (to extract the number of volunteers each night) with data from `inspectionview`, and sums the data for all interactions over the night (for example, counting how many interactions had each type of outcome).

## Creating Power BI tables

The Power BI report uses a range of tables. These tables are constructed largely by combining historic CSV data with data extracted from Safety Culture.

- The table `places` is just a set of known places uploaded from CSV.

- The table `WelfareChecks` is a trivial copy of `welfarecheckview` to different column header names, combined with the contents of the uploaded `historic_welfare_checks` table.

- The table `AllDigitalSUF` is constructed from copying `all_suf_view` and combining it with the contents of the uploaded `historic_all_suf` table.

- The table `nightly_data` is constructed by copying `nightly_view` and combining it with the contents of the uploaded `historic_nightly` table.

## Other tables

*TODO: There are some other tables required by Power BI that do not exist in the Safety Culture data; to be provided.*


## Other tables

### Timing table

The table `dbo.JobTimestamp` contains a single timestamp, containing the last time an export was run successfully. It is read before each run, and updated afterwards on success.

This is because the Safety Culture exporter needs to be passed it in order to only download changes since the last time. If this table is dropped, then a full resync will be done.

