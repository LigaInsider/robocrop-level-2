*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret}=    Get and log the value of the vault secrets using the Get Secret keyword
    Open the robot order website
    ${orders}=    Get orders    ${secret}
    Log    ${orders}
    #FOR    ${row}    IN    @{orders}
    #    Close the annoying modal
    #    Fill the form    ${row}
    #    Preview the robot
    #    Submit the order
    #    ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    #    ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    #    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    #    Go to order another robot
    #END
    #Create a ZIP file of the receipts
    #Close the annoying modal
    #[Teardown]    Close the browser


*** Keywords ***
Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    credentials
    RETURN    ${secret}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${secret}
    Download    ${secret}[csvurl]    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Wait Until Page Contains Element    class:modal
    Click Button    Yep

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Click Element    class:form-control
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Wait Until Element Is Visible    id:robot-preview-image
    Click Button    order
    ${alert}=    Is Element Visible    class:alert-danger
    Log    ${alert}
    IF    ${alert}
        Sleep    2s
        Click Button    order
    END
    ${recipready}=    Is Element Visible    id:receipt
    WHILE    ${recipready} == ${False}
        Click Button    order
        ${recipready}=    Is Element Visible    id:receipt
    END

Take a screenshot of the robot
    [Arguments]    ${filename}
    ${preview}=    Set Variable    screenshot${/}${filename}.png
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${preview}
    RETURN    ${preview}

Store the receipt as a PDF file
    [Arguments]    ${filename}
    Wait Until Page Contains Element    id:receipt
    ${order_robot_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Set variable    receipts${/}${filename}.pdf
    Html To Pdf    ${order_robot_html}    ${OUTPUT_DIR}${/}${pdf}
    RETURN    ${pdf}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${preview}    ${recipe}
    Add Watermark Image To PDF    coverage=0.15
    ...    image_path=${OUTPUT_DIR}${/}${preview}
    ...    source_path=${OUTPUT_DIR}${/}${recipe}
    ...    output_path=${OUTPUT_DIR}${/}${recipe}

Go to order another robot
    Click Button    Order another robot

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}robotorders.zip    include=*.pdf

Close the browser
    Close Browser
