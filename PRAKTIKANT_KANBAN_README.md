# Praktikant Kanban Lightning Web Component

A drag-and-drop Kanban board Lightning Web Component for managing Praktikant attendance status in Salesforce. This component provides an intuitive interface for tracking and updating the attendance status of praktikants across three categories: Unentschuldigt, Anwesend, and Entschuldigt.

## Features

### 🎯 Core Functionality
- **Three-Column Kanban Board**: Visual representation of attendance statuses
- **Drag & Drop Support**: Move praktikants between status columns
- **Touch Support**: Fully functional on tablets and mobile devices
- **Reason Modal**: Mandatory reason input when marking as "Entschuldigt"
- **Real-time Updates**: Instant UI updates with data persistence
- **Record Count Display**: Shows count of records in each column

### 📱 Cross-Platform Support
- **Desktop**: Full mouse drag-and-drop functionality
- **Tablet**: Touch-optimized with visual feedback
- **Mobile**: Responsive design with touch support
- **Accessibility**: ARIA labels and keyboard navigation support

### 🛡️ Security & Permissions
- **Field-Level Security**: Respects FLS and CRUD permissions
- **Error Handling**: Comprehensive error handling and user feedback
- **Input Validation**: Server-side validation for all operations
- **Audit Trail**: Logging of status changes for compliance

## Object Requirements

### Primary Object: `Stundenerfassung_Praktikant__c`

#### Required Fields:
- `Name_Anzeige__c` (Text) - Display name of the praktikant
- `Name_Link__c` (Text/Email) - Contact information or link
- `Taetigkeit__c` (Text) - Current activity or role
- `AnwesendheitStatus__c` (Picklist) - Attendance status with values:
  - Unentschuldigt
  - Anwesend  
  - Entschuldigt

#### Optional Enhancement:
Consider adding a custom field `Entschuldigt_Grund__c` (Text Area) to store the reason when status is changed to "Entschuldigt".

## Installation Instructions

### 1. Deploy to Salesforce

```bash
# Using Salesforce CLI
sf project deploy start --source-dir force-app/main/default

# Or using VS Code with Salesforce Extension Pack:
# Right-click on force-app folder -> SFDX: Deploy Source to Org
```

### 2. Assign Permissions

Ensure users have the following permissions:
- Read access to `Stundenerfassung_Praktikant__c` object
- Edit access to `AnwesendheitStatus__c` field
- Access to the Lightning App Builder (for administrators)

### 3. Add to Page Layout

1. Open Lightning App Builder
2. Edit the desired App Page, Home Page, or Record Page
3. Drag the "Praktikant Kanban Board" component onto the page
4. Save and activate the page

## Component Files

```
force-app/main/default/
├── lwc/praktikantKanban/
│   ├── praktikantKanban.html          # Main template
│   ├── praktikantKanban.js            # Component controller
│   ├── praktikantKanban.css           # Component styles
│   └── praktikantKanban.js-meta.xml   # Metadata configuration
└── classes/
    ├── PraktikantKanbanController.cls     # Apex controller
    └── PraktikantKanbanControllerTest.cls # Test class
```

## Usage Guide

### Basic Operations

1. **View Records**: Records are automatically displayed in their respective status columns
2. **Drag to Move**: Click and drag a praktikant card to move between columns
3. **Touch & Drop**: On tablets, touch and drag to move records
4. **Status Updates**: Records are automatically updated when moved

### Status Change to "Entschuldigt"

1. Drag any record to the "Entschuldigt" column
2. A modal will appear requesting a reason
3. Enter the reason for the absence
4. Click "Confirm" to save the change
5. The record will be updated with the new status

### Visual Feedback

- **Drag State**: Cards show visual feedback during dragging
- **Drop Zones**: Columns highlight when a record can be dropped
- **Loading States**: Spinner shown during data updates
- **Toast Messages**: Success/error notifications
- **Record Counts**: Real-time count updates in column headers

## Customization

### Styling

The component uses CSS custom properties that can be overridden:

```css
/* In your org's CSS file */
.kanban-column {
  --column-bg: #f8f9fa;
  --border-radius: 8px;
}

.unentschuldigt-header {
  --header-bg: linear-gradient(135deg, #d73527, #e74c3c);
}
```

### Extending Functionality

To add additional fields to the display:

1. Update the SOQL query in `PraktikantKanbanController.getPraktikantRecords()`
2. Add the fields to the HTML template in `praktikantKanban.html`
3. Update the CSS for proper styling

## API Reference

### Apex Methods

#### `getPraktikantRecords()`
- **Type**: `@AuraEnabled(cacheable=true)`
- **Returns**: `List<Stundenerfassung_Praktikant__c>`
- **Description**: Retrieves all praktikant records with required fields

#### `updatePraktikantStatus(recordId, newStatus, reason)`
- **Type**: `@AuraEnabled`
- **Parameters**:
  - `recordId` (String): ID of the record to update
  - `newStatus` (String): New attendance status
  - `reason` (String): Reason for the change (required for Entschuldigt)
- **Returns**: `String` - Success message
- **Description**: Updates the attendance status of a praktikant record

#### `getAnwesendheitStatusOptions()`
- **Type**: `@AuraEnabled(cacheable=true)`
- **Returns**: `List<String>`
- **Description**: Returns available picklist values for attendance status

### JavaScript Methods

#### Public Methods
- `refreshData()`: Manually refresh component data

#### Event Handlers
- `handleDragStart()`, `handleDrop()`: Desktop drag-drop events
- `handleTouchStart()`, `handleTouchEnd()`: Mobile touch events
- `handleReasonChange()`: Modal reason input handling

## Testing

### Running Tests

```bash
# Run Apex tests
sf apex run test --class-names PraktikantKanbanControllerTest

# Or in VS Code:
# Right-click on test class -> SFDX: Run Apex Tests
```

### Test Coverage
- `PraktikantKanbanController`: 100% code coverage
- Includes positive and negative test scenarios
- Tests for permissions and error handling

## Browser Compatibility

- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+
- ✅ Mobile Safari (iOS 13+)
- ✅ Chrome Mobile (Android 8+)

## Troubleshooting

### Common Issues

#### Records Not Loading
- Check object and field-level security
- Verify the object name matches your org configuration
- Check for any custom field API names

#### Drag-Drop Not Working
- Ensure JavaScript is enabled
- Check browser console for errors
- Verify touch events on mobile devices

#### Status Updates Failing
- Check user permissions for the object and fields
- Verify picklist values match exactly
- Check Apex debug logs for detailed error messages

### Debug Mode

Enable debug mode by opening browser console and running:
```javascript
// Enable debug logging
localStorage.setItem('lwc-debug', 'true');
```

## Performance Considerations

- **Cacheable Methods**: Data retrieval methods are cached for performance
- **Batch Updates**: Use bulk operations for multiple record updates
- **Responsive Design**: Optimized for various screen sizes
- **Touch Optimization**: Efficient touch event handling

## Contributing

To contribute to this component:

1. Follow Salesforce development best practices
2. Include comprehensive test coverage
3. Update documentation for any changes
4. Test on multiple devices and browsers

## License

This component is provided as-is for educational and development purposes. Please ensure compliance with your organization's coding standards and security requirements.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Salesforce debug logs
3. Test in a sandbox environment first
4. Ensure all requirements are met

---

**Version**: 1.0.0  
**Salesforce API Version**: 60.0  
**Last Updated**: December 2024