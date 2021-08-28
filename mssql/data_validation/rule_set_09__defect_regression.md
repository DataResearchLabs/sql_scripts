### Data Validation Examples - MS SQL Server
[![License: CC0](https://img.shields.io/badge/License-CC0-red)](LICENSE "Creative Commons Zero License by DataResearchLabs (effectively = Public Domain")
[![YouTube](https://img.shields.io/badge/YouTube-DataResearchLabs-brightgreen)](http://www.DataResearchLabs.com)
#### [Return to Data Validation Home Page](https://github.com/DataResearchLabs/sql_scripts/blob/main/data_validation_scripts.md)
<br>

# Rule Set #9 - Defect Regression

## Summary
Where possible, it is a good idea to cover known defects with a test case.  This enables automated regression testing for free.  Yuo can simply run this script to quickly re-check whether a defect has been re-introduced.

There are a lot of caveats that will block you from covering every defect:
* If anything but the simplest of setup and tear down data is required 
* If processes or jobs or applications or ETL must be triggered
* If there are interactions with other databases or files not on the current server

That said, you can still frequently setup static trip wires to monitor the data for recurrence of old bugs.  

Some real-world examples from my past include:
* A defect where email addresses stored in the database had TAB characters.  I setup a simple CHAR(9) check that ran daily and cross referenced the defect number in the SQL return results.
* A defect where customer specific HTML snippets for email reports had bad tags manually entered by company analysts working with the client.  Obviously fixing the app to avoid those data entries would be best, but that was a different department that was going to get to it later.  So, I setup a daily alert to check for those HTML tags and some other similar ones that might be accidentally introduced.
* A defect where internal data entry folks on rare occasions had to key in customer names.  They were supposed to be all upper case for other reasons in the system, but the analysts sometimes entered lower case.  Developers were not going to get around to fixing it for a couple of months (other priorities, this was a very low frequency issue).  So I setup a daily check to trip an alarm and notify via email the appropriate person to correct their data.
* Basically, you can take any of the test case examples in Rule Sets #1 thu #8 and apply them as regression tests for defects when appropriate. 
