# Design Doc: Material Widgets for VPAT Assessment

**Author:** Antigravity
**Status:** Draft

## Objective

Identify and categorize Material widgets in the Flutter framework that are commonly used by developers and should be prioritized for a Voluntary Product Accessibility Template (VPAT) assessment.

## Background

To ensure compliance with accessibility standards, key interactive and structural components of the Material library need to be evaluated. This document outlines the target widgets and marks those already partially covered by existing assessment infrastructure.

## Target widgets

The following sections list the candidate widgets grouped by functional category. Widgets that are already present in `dev/a11y_assessments` are noted.

### Buttons and interaction

These widgets are primary targets for accessibility as they must handle focus, keyboard navigation, and screen reader announcements correctly.

*   ElevatedButton
*   FilledButton
*   OutlinedButton
*   TextButton (Included in a11y_assessments)
*   IconButton
*   FloatingActionButton
*   PopupMenuButton
*   SegmentedButton
*   ToggleButtons
*   BackButton
*   CloseButton
*   AboutListTile
*   InkWell (used to add touch interactives to custom widgets)
*   InkResponse

### Selection controls

These widgets change state and need to communicate that state clearly to accessibility services.

*   Checkbox
*   Radio
*   Switch
*   CheckboxListTile (Included in a11y_assessments)
*   RadioListTile (Included in a11y_assessments)
*   SwitchListTile (Included in a11y_assessments)

### Text inputs

Text fields are among the most complex widgets for accessibility, handling focus, text selection, and error states.

*   TextField (Included in a11y_assessments)
*   TextFormField
*   Autocomplete (Included in a11y_assessments)
*   SearchBar
*   SearchAnchor
*   DropdownMenu
*   DropdownButton

### Menus

Material 3 introduced new menu widgets that are important for accessibility.

*   MenuAnchor
*   MenuBar
*   MenuItemButton
*   SubmenuButton

### Navigation components

These widgets help users find their way around an app and need to support efficient keyboard traversal and semantic structure.

*   AppBar (Included in a11y_assessments)
*   BottomAppBar
*   NavigationBar (Included in a11y_assessments)
*   BottomNavigationBar
*   NavigationRail (Included in a11y_assessments)
*   Drawer (Included in a11y_assessments)
*   NavigationDrawer (Included in a11y_assessments)
*   TabBar
*   TabBarView (Included in a11y_assessments)

### Dialogs and overlays

These widgets interrupt the user flow or provide contextual information, requiring careful focus management.

*   AlertDialog (Covered by Dialog in a11y_assessments)
*   SimpleDialog (Covered by Dialog in a11y_assessments)
*   AboutDialog
*   BottomSheet
*   SnackBar (Included in a11y_assessments)
*   MaterialBanner (Included in a11y_assessments)
*   Tooltip

### Layout and content containers

These provide structure and should convey semantic meaning to screen readers.

*   Card (Included in a11y_assessments)
*   ListTile
*   ExpansionTile (Included in a11y_assessments)
*   ExpansionPanelList
*   ExpansionPanel
*   DataTable
*   PaginatedDataTable
*   GridTile
*   GridTileBar
*   UserAccountsDrawerHeader

### Sliders and pickers

These involve complex gestures or multiple interactive elements.

*   Slider (Included in a11y_assessments)
*   RangeSlider (Included in a11y_assessments)
*   DatePicker (Included in a11y_assessments)
*   TimePicker

### Indicators and informative widgets

These display status and should be announced or readable by screen readers.

*   CircularProgressIndicator
*   LinearProgressIndicator
*   RefreshIndicator
*   Stepper
*   ActionChip (Included in a11y_assessments)
*   FilterChip
*   ChoiceChip
*   InputChip
*   Badge (Included in a11y_assessments)
*   CarouselView
