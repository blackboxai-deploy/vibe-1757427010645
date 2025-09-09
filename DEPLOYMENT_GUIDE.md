# Praktikant Kanban - Deployment Guide

This guide provides step-by-step instructions for deploying the Praktikant Kanban Lightning Web Component to your Salesforce org.

## Prerequisites

### Required Tools
- **Salesforce CLI**: Install from [Salesforce CLI Setup](https://developer.salesforce.com/tools/sfdxcli)
- **VS Code** (Recommended): With Salesforce Extension Pack
- **Git**: For version control
- **Connected Salesforce Org**: With appropriate permissions

### Required Permissions
- System Administrator profile (for initial deployment)
- Lightning App Builder access
- Custom Object creation and modification permissions

## Step 1: Environment Setup

### 1.1 Install Salesforce CLI
```bash
# For macOS using Homebrew
brew install salesforce/salesforce/sfdx

# For Windows (download installer from Salesforce)
# https://developer.salesforce.com/tools/sfdxcli

# Verify installation
sf version
```

### 1.2 Set Up VS Code (Recommended)
1. Install VS Code from https://code.visualstudio.com/
2. Install Salesforce Extension Pack
3. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
4. Run: "SFDX: Create Project with Manifest"

### 1.3 Authenticate to Your Org
```bash
# Authenticate to your org
sf org login web --alias MyPraktikantOrg

# Set as default org
sf config set target-org MyPraktikantOrg
```

## Step 2: Object and Field Setup

### 2.1 Create Custom Object (if not exists)

Navigate to Setup > Object Manager and create:

**Object Name**: `Stundenerfassung_Praktikant__c`
- **Label**: Stundenerfassung Praktikant
- **Plural Label**: Stundenerfassung Praktikanten
- **Object Name**: Stundenerfassung_Praktikant
- **Record Name**: Auto Number (SP-{0000})

### 2.2 Create Required Fields

Create the following custom fields:

#### Name_Anzeige__c (Text)
- **Field Label**: Name Anzeige
- **Length**: 255
- **Field Name**: Name_Anzeige
- **Required**: Yes

#### Name_Link__c (Text/Email)
- **Field Label**: Name Link
- **Length**: 255
- **Field Name**: Name_Link
- **Required**: No

#### Taetigkeit__c (Text)
- **Field Label**: Tätigkeit
- **Length**: 255
- **Field Name**: Taetigkeit
- **Required**: No

#### AnwesendheitStatus__c (Picklist)
- **Field Label**: Anwesenheit Status
- **Field Name**: AnwesendheitStatus
- **Values**:
  - Unentschuldigt
  - Anwesend
  - Entschuldigt
- **Default Value**: Anwesend
- **Required**: Yes

### 2.3 Optional: Reason Field
```
Field Label: Entschuldigt Grund
Field Name: Entschuldigt_Grund__c
Data Type: Text Area (Long)
Length: 32,768
Required: No
```

## Step 3: Code Deployment

### 3.1 Project Structure
Ensure your project has this structure:
```
force-app/main/default/
├── lwc/praktikantKanban/
│   ├── praktikantKanban.html
│   ├── praktikantKanban.js
│   ├── praktikantKanban.css
│   └── praktikantKanban.js-meta.xml
└── classes/
    ├── PraktikantKanbanController.cls
    └── PraktikantKanbanControllerTest.cls
```

### 3.2 Deploy Using Salesforce CLI

```bash
# Navigate to project directory
cd /path/to/your/project

# Deploy all metadata
sf project deploy start --source-dir force-app/main/default

# Or deploy specific components
sf project deploy start --source-dir force-app/main/default/lwc/praktikantKanban
sf project deploy start --source-dir force-app/main/default/classes
```

### 3.3 Deploy Using VS Code

1. Open project in VS Code
2. Right-click on `force-app` folder
3. Select "SFDX: Deploy Source to Org"
4. Wait for deployment to complete

### 3.4 Verify Deployment

```bash
# Check deployment status
sf project deploy start --source-dir force-app/main/default --wait 10

# Run tests
sf apex run test --class-names PraktikantKanbanControllerTest --wait 10
```

## Step 4: Configuration

### 4.1 Set Up Permissions

#### Permission Set (Recommended)
1. Setup > Permission Sets > New
2. **Label**: Praktikant Kanban User
3. **API Name**: Praktikant_Kanban_User

#### Assign Object Permissions:
- **Object**: Stundenerfassung_Praktikant__c
- **Permissions**: Read, Create, Edit, Delete, View All, Modify All

#### Assign Field Permissions:
- All custom fields: Read and Edit access
- Apex Classes: PraktikantKanbanController (Enabled)

### 4.2 Create Sample Data (Optional)

```bash
# Create sample records using Data Loader or Apex Anonymous
# Open Developer Console > Debug > Open Execute Anonymous Window
```

```apex
List<Stundenerfassung_Praktikant__c> testData = new List<Stundenerfassung_Praktikant__c>();

testData.add(new Stundenerfassung_Praktikant__c(
    Name_Anzeige__c = 'Max Mustermann',
    Name_Link__c = 'max.mustermann@company.com',
    Taetigkeit__c = 'Software Development',
    AnwesendheitStatus__c = 'Anwesend'
));

testData.add(new Stundenerfassung_Praktikant__c(
    Name_Anzeige__c = 'Anna Schmidt',
    Name_Link__c = 'anna.schmidt@company.com',
    Taetigkeit__c = 'Quality Assurance',
    AnwesendheitStatus__c = 'Unentschuldigt'
));

testData.add(new Stundenerfassung_Praktikant__c(
    Name_Anzeige__c = 'John Doe',
    Name_Link__c = 'john.doe@company.com',
    Taetigkeit__c = 'Data Analysis',
    AnwesendheitStatus__c = 'Entschuldigt'
));

insert testData;
System.debug('Test data created: ' + testData.size() + ' records');
```

## Step 5: Page Configuration

### 5.1 Add to Lightning App

1. **App Manager** > Select your Lightning App > Edit
2. **Navigation** > Add "Praktikant Kanban" tab
3. Save and assign to user profiles

### 5.2 Add to Home Page

1. **Setup** > **Home Page Layouts**
2. **App Builder** > Edit Home Page
3. **Components** > Find "Praktikant Kanban Board"
4. Drag to desired location
5. Save and Activate

### 5.3 Add to App Page

1. **App Builder** > New > App Page
2. Choose template > Next
3. **Components** > Custom Components > "Praktikant Kanban Board"
4. Drag to page canvas
5. Save and Activate
6. Assign to Lightning App

### 5.4 Add to Record Page (Optional)

1. **App Builder** > Object Record Page
2. Choose object > Next > Choose template
3. Add component to desired section
4. Save and Activate

## Step 6: Testing and Validation

### 6.1 Run Apex Tests

```bash
# Run specific test class
sf apex run test --class-names PraktikantKanbanControllerTest

# Run all tests in org
sf apex run test --wait 10

# Check test results
sf apex get test --test-run-id YOUR_TEST_RUN_ID
```

### 6.2 Manual Testing Checklist

- [ ] Component loads without errors
- [ ] Records display in correct columns
- [ ] Drag and drop works on desktop
- [ ] Touch drag works on tablet/mobile
- [ ] Reason modal appears for Entschuldigt moves
- [ ] Status updates persist in database
- [ ] Error handling works correctly
- [ ] Loading states display properly
- [ ] Record counts update correctly

### 6.3 Cross-Browser Testing

Test on:
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

## Step 7: User Training

### 7.1 Create User Guide

- Document basic operations
- Explain drag-drop functionality
- Show reason modal process
- Include troubleshooting tips

### 7.2 Conduct Training Sessions

- Demonstrate component functionality
- Practice drag-drop operations
- Explain tablet/mobile usage
- Address user questions

## Troubleshooting

### Common Deployment Issues

#### Issue: "FIELD_CUSTOM_VALIDATION_EXCEPTION"
**Solution**: Check field validations and required field values

#### Issue: "INVALID_CROSS_REFERENCE_KEY"
**Solution**: Ensure all referenced fields exist in target org

#### Issue: Component not visible in App Builder
**Solution**: Check metadata file and ensure proper target configuration

#### Issue: "Insufficient Privileges"
**Solution**: Ensure user has proper permissions and FLS access

### Debugging Tips

```bash
# View deployment errors
sf project deploy start --source-dir force-app/main/default --verbose

# Check org limits
sf org display limits

# View debug logs
sf apex log tail --color
```

## Rollback Plan

### If Issues Occur:

1. **Disable Component**: Remove from page layouts
2. **Rollback Code**: Use Git to revert changes
3. **Remove Deployment**: 
   ```bash
   sf project delete source --source-dir force-app/main/default/lwc/praktikantKanban
   ```

### Data Backup:

```bash
# Export data before deployment
sf data export tree --query "SELECT Id, Name_Anzeige__c, AnwesendheitStatus__c FROM Stundenerfassung_Praktikant__c" --output-dir backup/
```

## Post-Deployment Checklist

- [ ] All tests pass (>75% code coverage)
- [ ] Component loads in target environments
- [ ] Permissions configured correctly
- [ ] Sample data created (if needed)
- [ ] User training completed
- [ ] Documentation updated
- [ ] Monitoring enabled
- [ ] Backup procedures in place

## Support and Maintenance

### Regular Tasks:
- Monitor error logs
- Update test data as needed
- Review user feedback
- Plan enhancement releases

### Performance Monitoring:
- Check query performance
- Monitor heap size usage
- Review governor limits
- Analyze user adoption metrics

---

**Deployment Version**: 1.0.0  
**Last Updated**: December 2024  
**Contact**: System Administrator