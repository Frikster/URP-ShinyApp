# URP-ShinyApp

URP-ShinyApp provides an online interface to the R [party package](https://cran.r-project.org/web/packages/party/index.html). Users can upload a CSV, select which columns to include or exclude as predictors to produce a [URP-ctree](#unbiased-recursive-partitioning-urp) that shows a decision tree with predictor splits leading to the selected "anchor" target variable.

[Live site](https://urpanalyses.shinyapps.io/URP-ShinyApp/)
[Academic Poster]()

## Screenshots

In the examples below a row in the CSV uploaded represents a single patient with Spinal Chord Injury. Note the app is agnostic regarding your data. Financial data will work just as well as clinical data.

![2Weeks-6min12Months](/assets/2Weeks-6min12Months.png)

Above we see an example where predictors (i.e. columns in the CSV) with the substring "2Weeks" in their headers are selected and the anchor is a column with the header "at6min.12Months." Columns with a header appended with "2Weeks" are metrics recorded within 2 weeks after injury. The column with the header "at6min.12Months" contains numeric data on how far a patient could walk for six minutes 12 months after injury.

This essentially presents us with a decision tree showing us which predictors within 2 weeks of injury best predict what the patient's 6 minute walk distance will be at 12 months.

![2Weeks-ASIAGrade12Months](/assets/2Weeks-ASIAGrade12Months.png)

An example where the anchor is set to a column in the CSV that is each row's [ASIA Grade](https://www.physio-pedia.com/American_Spinal_Injury_Association_(ASIA)_Impairment_Scale) which is an ordinal value of A, B, C or D. This shows the same concept as the previous example and is meant to illustrate how ordinal values are handled.

## Overview

### Subsetting Tab

![SubsettingTab](/assets/SubsettingTab.png)

In the subsetting tab CSV data is uploaded. After upload is complete it is recommended to verify that columns can be selected and displayed. Any data that is subsetted here is the data that is used to display the [ctrees](#conditional-inference-trees-ctree) in the URP tab. 

In this sccreenshot we can see that we are subsetting the uploaded CSV such that only female patients that were under the age of 70 at the date of their injury (DOI). These are the patients that were used to generate the [screenshots](#screenshots).

### URP Tab

See [Screenshots](#screenshot-of-the-app)

### URP-Table Tab

![URP-tableTab](/assets/URP-tableTab.png)

In the URP-Table tab we can view the data that comprises the ctrees that were plotted in the URP tab, including the leaf nodes data was sorted into. This data can be downloaded.

In this example, consider node 4 for the ctree in the [screenshots](#screenshots) section where the anchor was "at6min.12Months" (i.e. the tree with the title: *Characteristics at 2 Weeks to Predict 6 Min Walk Distance at 12 Months*). We can notice how almost all patients in this cohort have no walking ability at 6months, except for 3. This tab allows us to quickly look at those 3 patients and see what other characteristics they might have. In this example we additionally display their AIS Grades at 2 weeks and 12 months.

##  Limitations

This app is no longer maintained and running code written almost a decade ago by an undergrad without any prior real-world coding experience. Adjust expectations accordingly.

- **Upload limit:** CSV files can only be so large. In practice this is fine as [URP-ctrees](#unbiased-recursive-partitioning-urp) are more computationally demanding to generate than traditional decision trees and are thus more suited to smaller datasets
- **Processing time:** After clicking "Plot URP-CTree" there is unfortunately no visual indicator that processing is occurring the first time a tree is plotted. Subsequent plots will show processing is occurring by graying out the previous plot before replacing it with a new one.
  - Readjusting the width and height of the chart recomputes the entire decision tree which can be time-consuming. 
- **User limit:** Only one person can use the app at a time while a URP-ctree is being processed. If a second user attempts to use the app concurrently loading will come to a standstill and may return a 504 Gateway Timeout unless processing of the other user is complete
  - There are paid R Shiny server options to mitigate this. Since this project is no longer actively maintained, only free-tier R Shiny servers are in use.
  - I'm happy to deploy the app on AWS if there is ever significant enough interest in the app. Feel free to [reach out](https://www.linkedin.com/in/dirk-haupt-a1296316/).
- **No data persistence:** No data is stored. If you refresh your tab you will lose everything and have to upload your csv again. The app is meant for exploratory analysis only
- **"cohort" vs "node":** Due to demands from users "node" as is commonly used in data science was replaced with "cohort" to suit clinical research expectations. However the word "node" still appears elsewhere in the app. These words are interchangeable. Apologies for any confusion.

# Unbiased Recursive Partitioning (URP):

Refers to the general idea of recursively splitting data in a way that is unbiased toward the number of cutpoints a predictor has. The traditional [CART](https://www.geeksforgeeks.org/cart-classification-and-regression-tree-in-machine-learning/) method, for instance, can show a bias towards variables with a larger number of potential splits.

URP ensures that variables with fewer categories or potential cutpoints aren't at a disadvantage when determining the best split.

## Conditional Inference Trees (ctree):

This is a specific implementation of the URP idea. It utilizes statistical tests to determine the significance of splits. Instead of selecting splits based on maximization of a purity criterion (like Gini impurity or information gain as in CART), ctree uses a sequence of formal statistical tests to determine the association between predictors and the response. If a significant association is found, the predictor with the strongest association is selected for splitting. This framework prevents overfitting, as insignificant splits are not pursued. Consequently, ctree doesn't require a separate pruning step.

Please see the following publication for further information: [Hothorn, T., Hornik, K., & Zeileis, A. (2006). *Unbiased Recursive Partitioning: A Conditional Inference Framework.*](https://www.zeileis.org/papers/Hothorn+Hornik+Zeileis-2006.pdf)

# Supplementary Example

Click [here](https://world.hey.com/dirkh/627db2e6/blobs/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHNLd2Y0L0ZOUCIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--50d37d2a07f771942e6a1462d142c1c270e97762/draft%20%237%20Montreal%20Posters.pdf) to view academic posters that are meant to showcase what kind of exploratory analysis can rapidly be conducted, without requiring any scripting, with the aid of URP-ShinyApp.