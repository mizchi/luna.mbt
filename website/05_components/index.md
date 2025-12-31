---
title: Component Catalog
---

# Radix Component Catalog

Luna provides 77 headless UI components inspired by [Radix UI](https://radix-ui.com/) and [shadcn/ui](https://ui.shadcn.com/).

## Live Demo - Hydration on Visible

The components below demonstrate Luna's Island hydration with `trigger="visible"` - JavaScript only loads when scrolled into view:

<Island name="counter-1" :props='{"initial": 0}' trigger="visible" />

<Island name="counter-2" :props='{"initial": 10}' trigger="visible" />

> 💡 **Note**: These counters use `trigger="visible"` (Intersection Observer). Scroll down to see them hydrate!

Each component comes in three variants:
- **Headless** (`radix_xxx`) - Unstyled with semantic HTML and data attributes
- **Styled** (`radix_xxx_styled`) - Declarative Shadow DOM with encapsulated styles
- **UCSS** (`radix_xxx_ucss`) - Atomic CSS classes via luna/css

## Layout & Structure

| Component | Description |
|-----------|-------------|
| [AspectRatio](#aspect-ratio) | Maintain aspect ratio for content |
| [Card](#card) | Container with header, content, footer |
| [Separator](#separator) | Visual divider |
| [Resizable](#resizable) | Resizable panels |
| [ScrollArea](#scroll-area) | Custom scrollbar container |

## Navigation

| Component | Description |
|-----------|-------------|
| [Breadcrumb](#breadcrumb) | Navigation breadcrumb trail |
| [NavigationMenu](#navigation-menu) | Site navigation menu |
| [Menubar](#menubar) | Application menubar |
| [Pagination](#pagination) | Page navigation |
| [Tabs](#tabs) | Tabbed interface |
| [Sidebar](#sidebar) | Collapsible sidebar |
| [Stepper](#stepper) | Multi-step wizard |

## Forms & Inputs

| Component | Description |
|-----------|-------------|
| [Button](#button) | Interactive button |
| [Input](#input) | Text input field |
| [Textarea](#textarea) | Multi-line text input |
| [NumberInput](#number-input) | Number input with +/- buttons |
| [Checkbox](#checkbox) | Checkbox input |
| [Radio](#radio) | Radio button group |
| [Switch](#switch) | Toggle switch |
| [Slider](#slider) | Single value slider |
| [RangeSlider](#range-slider) | Dual-handle range slider |
| [Select](#select) | Dropdown select |
| [Combobox](#combobox) | Searchable select |
| [AutoComplete](#autocomplete) | Input with suggestions |
| [InputOTP](#input-otp) | OTP/PIN input |
| [Label](#label) | Form label |
| [Toggle](#toggle) | Toggle button |
| [ToggleGroup](#toggle-group) | Group of toggle buttons |
| [Rating](#rating) | Star rating |
| [ColorPicker](#color-picker) | Color selection |
| [FileUpload](#file-upload) | File upload with drag & drop |
| [Mentions](#mentions) | @ mentions input |

## Date & Time

| Component | Description |
|-----------|-------------|
| [Calendar](#calendar) | Date calendar |
| [DatePicker](#date-picker) | Date selection |
| [DateRangePicker](#date-range-picker) | Date range selection |
| [TimePicker](#time-picker) | Time selection |
| [Countdown](#countdown) | Countdown timer display |

## Overlays & Modals

| Component | Description |
|-----------|-------------|
| [Dialog](#dialog) | Modal dialog |
| [AlertDialog](#alert-dialog) | Confirmation dialog |
| [Sheet](#sheet) | Slide-in panel |
| [Drawer](#drawer) | Bottom/side drawer |
| [Popover](#popover) | Floating popover |
| [Tooltip](#tooltip) | Hover tooltip |
| [HoverCard](#hover-card) | Preview on hover |
| [ContextMenu](#context-menu) | Right-click menu |
| [DropdownMenu](#dropdown-menu) | Dropdown menu |
| [Command](#command) | Command palette |

## Data Display

| Component | Description |
|-----------|-------------|
| [Table](#table) | Data table |
| [Avatar](#avatar) | User avatar |
| [AvatarGroup](#avatar-group) | Stacked avatars |
| [Badge](#badge) | Status badge |
| [Tag](#tag) | Label tag |
| [Skeleton](#skeleton) | Loading placeholder |
| [Progress](#progress) | Progress bar |
| [Spinner](#spinner) | Loading spinner |
| [Empty](#empty) | Empty state |
| [Statistic](#statistic) | Statistic display |
| [Timeline](#timeline) | Vertical timeline |
| [Tree](#tree) | Tree view |

## Feedback

| Component | Description |
|-----------|-------------|
| [Alert](#alert) | Alert message |
| [Callout](#callout) | Highlighted info box |
| [Toast](#toast) | Toast notification |
| [Result](#result) | Operation result page |

## Typography

| Component | Description |
|-----------|-------------|
| [Blockquote](#blockquote) | Quote block |
| [Code](#code) | Inline/block code |
| [Kbd](#kbd) | Keyboard shortcut |
| [List](#list) | Ordered/unordered list |
| [DescriptionList](#description-list) | Key-value list |

## Utilities

| Component | Description |
|-----------|-------------|
| [Accordion](#accordion) | Expandable sections |
| [Collapsible](#collapsible) | Collapsible content |
| [Carousel](#carousel) | Image/content carousel |
| [Image](#image) | Lazy loading image |
| [BackTop](#back-top) | Back to top button |
| [FAB](#fab) | Floating action button |
| [CopyButton](#copy-button) | Copy to clipboard |
| [SegmentedControl](#segmented-control) | iOS-style segmented control |
| [Toolbar](#toolbar) | Toolbar container |

---

## Component Details

### Accordion

Expandable content sections with header triggers.

```moonbit
radix_accordion(
  accordion_type=Single,
  collapsible=true,
  children=[
    radix_accordion_item(value="item-1", children=[
      radix_accordion_trigger(children=[@luna.text("Section 1")]),
      radix_accordion_content(children=[@luna.text("Content 1")]),
    ]),
  ],
)
```

### Alert

Alert message with icon and description.

```moonbit
radix_alert(variant=Destructive, children=[
  radix_alert_title(children=[@luna.text("Error")]),
  radix_alert_description(children=[@luna.text("Something went wrong.")]),
])
```

### AlertDialog

Modal confirmation dialog.

```moonbit
radix_alert_dialog(open=true, children=[
  radix_alert_dialog_content(children=[
    radix_alert_dialog_title(children=[@luna.text("Confirm")]),
    radix_alert_dialog_description(children=[@luna.text("Are you sure?")]),
    radix_alert_dialog_action(children=[@luna.text("Confirm")]),
    radix_alert_dialog_cancel(children=[@luna.text("Cancel")]),
  ]),
])
```

### AspectRatio

Maintain aspect ratio for images or video.

```moonbit
radix_aspect_ratio(ratio="16/9", children=[
  radix_image_img("image.jpg", "Description"),
])
```

### AutoComplete

Input with dropdown suggestions.

```moonbit
radix_autocomplete(open=true, children=[
  radix_autocomplete_input(placeholder="Search..."),
  radix_autocomplete_content(children=[
    radix_autocomplete_item("option1", children=[@luna.text("Option 1")]),
    radix_autocomplete_item("option2", children=[@luna.text("Option 2")]),
  ]),
])
```

### Avatar

User avatar with image and fallback.

```moonbit
radix_avatar(children=[
  radix_avatar_image(src="/avatar.jpg", alt="User"),
  radix_avatar_fallback(children=[@luna.text("JD")]),
])
```

### AvatarGroup

Stacked avatar display with overflow.

```moonbit
radix_avatar_group(max=3, children=[
  radix_avatar_group_item(children=[...]),
  radix_avatar_group_item(children=[...]),
  radix_avatar_group_overflow(2),
])
```

### BackTop

Scroll to top button.

```moonbit
radix_back_top(visible=true, children=[
  @luna.text("^"),
])
```

### Badge

Status badge with variants.

```moonbit
radix_badge(variant=Secondary, children=[@luna.text("New")])
```

### Blockquote

Styled quote block.

```moonbit
radix_blockquote(children=[@luna.text("To be or not to be...")])
```

### Breadcrumb

Navigation breadcrumb.

```moonbit
radix_breadcrumb(children=[
  radix_breadcrumb_list(children=[
    radix_breadcrumb_item(children=[radix_breadcrumb_link("/", children=[@luna.text("Home")])]),
    radix_breadcrumb_separator(),
    radix_breadcrumb_item(children=[radix_breadcrumb_page(children=[@luna.text("Current")])]),
  ]),
])
```

### Button

Interactive button with variants.

```moonbit
radix_button(variant=Primary, size=Md, children=[@luna.text("Click me")])
```

### Calendar

Date calendar for selection.

```moonbit
radix_calendar(children=[
  radix_calendar_header(children=[
    radix_calendar_prev_button(),
    radix_calendar_heading("December 2024"),
    radix_calendar_next_button(),
  ]),
  radix_calendar_grid(children=[...]),
])
```

### Callout

Highlighted information box.

```moonbit
radix_callout(variant=Info, children=[
  radix_callout_icon(children=[...]),
  radix_callout_content(children=[
    radix_callout_title(children=[@luna.text("Note")]),
    radix_callout_description(children=[@luna.text("Important info here.")]),
  ]),
])
```

### Card

Container card with sections.

```moonbit
radix_card(children=[
  radix_card_header(children=[
    radix_card_title(children=[@luna.text("Title")]),
    radix_card_description(children=[@luna.text("Description")]),
  ]),
  radix_card_content(children=[...]),
  radix_card_footer(children=[...]),
])
```

### Carousel

Image/content carousel.

```moonbit
radix_carousel(children=[
  radix_carousel_content(children=[
    radix_carousel_item(children=[...]),
    radix_carousel_item(children=[...]),
  ]),
  radix_carousel_previous(),
  radix_carousel_next(),
])
```

### Checkbox

Checkbox input.

```moonbit
radix_checkbox(checked=true)
```

### Code

Inline and block code display.

```moonbit
radix_code_inline(children=[@luna.text("const x = 1")])
radix_code_block(language="javascript", children=[@luna.text("function foo() {}")])
```

### Collapsible

Collapsible content section.

```moonbit
radix_collapsible(open=true, children=[
  radix_collapsible_trigger(children=[@luna.text("Toggle")]),
  radix_collapsible_content(children=[@luna.text("Hidden content")]),
])
```

### ColorPicker

Color selection input.

```moonbit
radix_color_picker(value="#ff0000", children=[
  radix_color_picker_trigger(color="#ff0000", children=[
    radix_color_picker_swatch("#ff0000"),
  ]),
  radix_color_picker_content(children=[...]),
])
```

### Combobox

Searchable dropdown select.

```moonbit
radix_combobox(open=true, children=[
  radix_combobox_trigger(children=[...]),
  radix_combobox_content(children=[
    radix_combobox_input(placeholder="Search..."),
    radix_combobox_item("1", children=[@luna.text("Item 1")]),
  ]),
])
```

### Command

Command palette / search.

```moonbit
radix_command(children=[
  radix_command_input(placeholder="Type a command..."),
  radix_command_list(children=[
    radix_command_group(heading="Actions", children=[
      radix_command_item(children=[@luna.text("New File")]),
    ]),
  ]),
])
```

### ContextMenu

Right-click context menu.

```moonbit
radix_context_menu(children=[
  radix_context_menu_trigger(children=[@luna.text("Right click me")]),
  radix_context_menu_content(children=[
    radix_context_menu_item(children=[@luna.text("Edit")]),
    radix_context_menu_separator(),
    radix_context_menu_item(children=[@luna.text("Delete")]),
  ]),
])
```

### CopyButton

Copy to clipboard button.

```moonbit
radix_copy_button(state=Idle, value="Text to copy", children=[
  radix_copy_button_icon_idle(children=[...]),
  radix_copy_button_icon_copied(children=[...]),
])
```

### Countdown

Countdown timer display.

```moonbit
radix_countdown(children=[
  radix_countdown_segment("days", children=[
    radix_countdown_value("07"),
    radix_countdown_label("Days"),
  ]),
  radix_countdown_separator(),
  radix_countdown_segment("hours", children=[
    radix_countdown_value("12"),
    radix_countdown_label("Hours"),
  ]),
])
```

### DatePicker

Date selection with calendar.

```moonbit
radix_date_picker(open=true, children=[
  radix_date_picker_trigger(value="2024-12-31", children=[...]),
  radix_date_picker_content(children=[
    radix_calendar(children=[...]),
  ]),
])
```

### DateRangePicker

Date range selection.

```moonbit
radix_date_range_picker(open=true, children=[
  radix_date_range_picker_trigger(start_date="2024-01-01", end_date="2024-12-31", children=[...]),
  radix_date_range_picker_content(children=[
    radix_date_range_picker_calendars(children=[...]),
    radix_date_range_picker_presets(children=[
      radix_date_range_picker_preset("Last 7 days", "2024-12-24", "2024-12-31"),
    ]),
  ]),
])
```

### DescriptionList

Key-value display list.

```moonbit
radix_description_list(children=[
  radix_description_item(children=[
    radix_description_term(children=[@luna.text("Name")]),
    radix_description_details(children=[@luna.text("John Doe")]),
  ]),
])
```

### Dialog

Modal dialog.

```moonbit
radix_dialog(open=true, children=[
  radix_dialog_content(children=[
    radix_dialog_header(children=[
      radix_dialog_title(children=[@luna.text("Title")]),
      radix_dialog_description(children=[@luna.text("Description")]),
    ]),
    radix_dialog_footer(children=[...]),
  ]),
])
```

### Drawer

Slide-in drawer panel.

```moonbit
radix_drawer(open=true, side=Bottom, children=[
  radix_drawer_content(children=[
    radix_drawer_header(children=[...]),
    radix_drawer_body(children=[...]),
    radix_drawer_footer(children=[...]),
  ]),
])
```

### DropdownMenu

Dropdown menu.

```moonbit
radix_dropdown_menu(children=[
  radix_dropdown_menu_trigger(children=[@luna.text("Menu")]),
  radix_dropdown_menu_content(children=[
    radix_dropdown_menu_item(children=[@luna.text("Item 1")]),
    radix_dropdown_menu_separator(),
    radix_dropdown_menu_item(children=[@luna.text("Item 2")]),
  ]),
])
```

### Empty

Empty state placeholder.

```moonbit
radix_empty(children=[
  radix_empty_icon(children=[...]),
  radix_empty_title(children=[@luna.text("No data")]),
  radix_empty_description(children=[@luna.text("Get started by creating something.")]),
])
```

### FAB

Floating action button.

```moonbit
radix_fab(size=Md, position=BottomRight, children=[
  radix_fab_icon(children=[@luna.text("+")]),
])
```

### FileUpload

File upload with drag & drop.

```moonbit
radix_file_upload(children=[
  radix_file_upload_dropzone(dragging=false, children=[
    radix_file_upload_icon(children=[...]),
    radix_file_upload_label(children=[@luna.text("Drop files here")]),
    radix_file_upload_input(accept="image/*", multiple=true),
  ]),
  radix_file_upload_list(children=[
    radix_file_upload_item(children=[
      radix_file_upload_item_name(children=[@luna.text("file.jpg")]),
      radix_file_upload_item_size(children=[@luna.text("2.4 MB")]),
      radix_file_upload_item_remove(children=[@luna.text("x")]),
    ]),
  ]),
])
```

### HoverCard

Content preview on hover.

```moonbit
radix_hover_card(children=[
  radix_hover_card_trigger(children=[@luna.text("Hover me")]),
  radix_hover_card_content(children=[@luna.text("Preview content")]),
])
```

### Image

Image with lazy loading and fallback.

```moonbit
radix_image(state=Loaded, children=[
  radix_image_placeholder(blur_data_url="data:..."),
  radix_image_img("photo.jpg", "Description", lazy_load=true),
  radix_image_fallback(children=[@luna.text("Failed to load")]),
])
```

### Input

Text input field.

```moonbit
radix_input(input_type="text", placeholder="Enter text...", disabled=false)
```

### InputOTP

OTP/PIN code input.

```moonbit
radix_input_otp(length=6, children=[
  radix_input_otp_group(children=[
    radix_input_otp_slot(0, "1", active=false),
    radix_input_otp_slot(1, "2", active=false),
    radix_input_otp_slot(2, "", active=true),
  ]),
])
```

### Kbd

Keyboard shortcut display.

```moonbit
radix_kbd(children=[@luna.text("Ctrl+S")])
```

### Label

Form label.

```moonbit
radix_label(for_id="email", children=[@luna.text("Email")])
```

### List

Ordered/unordered list.

```moonbit
radix_list(ordered=false, children=[
  radix_list_item(children=[@luna.text("Item 1")]),
  radix_list_item(children=[@luna.text("Item 2")]),
])
```

### Mentions

@ mentions text input.

```moonbit
radix_mentions(open=true, children=[
  radix_mentions_textarea(placeholder="Type @ to mention..."),
  radix_mentions_dropdown(children=[
    radix_mentions_item("user1", children=[
      radix_mentions_item_avatar("/avatar.jpg", "User"),
      radix_mentions_item_name(children=[@luna.text("John Doe")]),
      radix_mentions_item_username(children=[@luna.text("@johndoe")]),
    ]),
  ]),
])
```

### Menubar

Application menubar.

```moonbit
radix_menubar(children=[
  radix_menubar_menu(children=[
    radix_menubar_trigger(children=[@luna.text("File")]),
    radix_menubar_content(children=[
      radix_menubar_item(children=[@luna.text("New")]),
      radix_menubar_item(children=[@luna.text("Open")]),
    ]),
  ]),
])
```

### NavigationMenu

Site navigation.

```moonbit
radix_navigation_menu(children=[
  radix_navigation_menu_list(children=[
    radix_navigation_menu_item(children=[
      radix_navigation_menu_trigger(children=[@luna.text("Products")]),
      radix_navigation_menu_content(children=[...]),
    ]),
  ]),
])
```

### NumberInput

Number input with increment/decrement.

```moonbit
radix_number_input(children=[
  radix_number_input_decrement(children=[@luna.text("-")]),
  radix_number_input_field(value="5", min="0", max="10", step="1"),
  radix_number_input_increment(children=[@luna.text("+")]),
])
```

### Pagination

Page navigation.

```moonbit
radix_pagination(children=[
  radix_pagination_content(children=[
    radix_pagination_previous(),
    radix_pagination_item(1, current=true),
    radix_pagination_item(2),
    radix_pagination_ellipsis(),
    radix_pagination_item(10),
    radix_pagination_next(),
  ]),
])
```

### Popover

Floating popover.

```moonbit
radix_popover(open=true, children=[
  radix_popover_trigger(children=[@luna.text("Open")]),
  radix_popover_content(children=[@luna.text("Popover content")]),
])
```

### Progress

Progress bar.

```moonbit
radix_progress(value=75, children=[
  radix_progress_indicator(75),
])
```

### Radio

Radio button group.

```moonbit
radix_radio_group(value="option1", children=[
  radix_radio_item("option1", checked=true),
  radix_radio_item("option2"),
])
```

### RangeSlider

Dual-handle range slider.

```moonbit
radix_range_slider(min="0", max="100", children=[
  radix_range_slider_track(children=[
    radix_range_slider_range(25, 75),
  ]),
  radix_range_slider_thumb(25, value="25"),
  radix_range_slider_thumb(75, value="75"),
])
```

### Rating

Star rating.

```moonbit
radix_rating(value=4, max=5, read_only=false, children=[...])
```

### Resizable

Resizable panels.

```moonbit
radix_resizable(direction=Horizontal, children=[
  radix_resizable_panel(default_size=50, children=[...]),
  radix_resizable_handle(),
  radix_resizable_panel(default_size=50, children=[...]),
])
```

### Result

Operation result display.

```moonbit
radix_result(status=Success, children=[
  radix_result_icon(children=[...]),
  radix_result_title(children=[@luna.text("Success!")]),
  radix_result_subtitle(children=[@luna.text("Your operation completed.")]),
  radix_result_extra(children=[
    radix_button(children=[@luna.text("Continue")]),
  ]),
])
```

### ScrollArea

Custom scrollbar container.

```moonbit
radix_scroll_area(children=[
  radix_scroll_area_viewport(children=[...]),
  radix_scroll_area_scrollbar(orientation=Vertical),
])
```

### SegmentedControl

iOS-style segmented control.

```moonbit
radix_segmented(children=[
  radix_segmented_item("tab1", selected=true, children=[@luna.text("Tab 1")]),
  radix_segmented_item("tab2", children=[@luna.text("Tab 2")]),
])
```

### Select

Dropdown select.

```moonbit
radix_select(open=true, children=[
  radix_select_trigger(children=[radix_select_value("Select...")]),
  radix_select_content(children=[
    radix_select_item("1", children=[@luna.text("Option 1")]),
    radix_select_item("2", children=[@luna.text("Option 2")]),
  ]),
])
```

### Separator

Visual divider.

```moonbit
radix_separator(orientation=Horizontal)
```

### Sheet

Slide-in panel.

```moonbit
radix_sheet(open=true, side=Right, children=[
  radix_sheet_content(children=[
    radix_sheet_header(children=[
      radix_sheet_title(children=[@luna.text("Sheet Title")]),
    ]),
    radix_sheet_body(children=[...]),
  ]),
])
```

### Sidebar

Collapsible sidebar navigation.

```moonbit
radix_sidebar(collapsed=false, children=[
  radix_sidebar_header(children=[...]),
  radix_sidebar_content(children=[
    radix_sidebar_group(children=[
      radix_sidebar_group_label(children=[@luna.text("Menu")]),
      radix_sidebar_menu(children=[
        radix_sidebar_menu_item(active=true, children=[@luna.text("Dashboard")]),
      ]),
    ]),
  ]),
  radix_sidebar_footer(children=[...]),
])
```

### Skeleton

Loading placeholder.

```moonbit
radix_skeleton(width="100%", height="1rem")
```

### Slider

Single value slider.

```moonbit
radix_slider(value=50, min=0, max=100, children=[
  radix_slider_track(children=[radix_slider_range(50)]),
  radix_slider_thumb(50),
])
```

### Spinner

Loading spinner.

```moonbit
radix_spinner(size=Md)
```

### Statistic

Statistic display.

```moonbit
radix_statistic(children=[
  radix_statistic_label(children=[@luna.text("Total Sales")]),
  radix_statistic_value(children=[
    radix_statistic_prefix(children=[@luna.text("$")]),
    @luna.text("12,345"),
  ]),
  radix_statistic_trend(Up, children=[@luna.text("+12%")]),
])
```

### Stepper

Multi-step wizard.

```moonbit
radix_stepper(orientation=Horizontal, children=[
  radix_stepper_item(status=Completed, children=[
    radix_stepper_trigger(1, "Step 1"),
  ]),
  radix_stepper_separator(),
  radix_stepper_item(status=Current, children=[
    radix_stepper_trigger(2, "Step 2"),
  ]),
])
```

### Switch

Toggle switch.

```moonbit
radix_switch(checked=true, disabled=false)
```

### Table

Data table.

```moonbit
radix_table(children=[
  radix_table_header(children=[
    radix_table_row(children=[
      radix_table_head(children=[@luna.text("Name")]),
      radix_table_head(children=[@luna.text("Email")]),
    ]),
  ]),
  radix_table_body(children=[
    radix_table_row(children=[
      radix_table_cell(children=[@luna.text("John")]),
      radix_table_cell(children=[@luna.text("john@example.com")]),
    ]),
  ]),
])
```

### Tabs

Tabbed interface.

```moonbit
radix_tabs(value="tab1", children=[
  radix_tabs_list(children=[
    radix_tabs_trigger("tab1", children=[@luna.text("Tab 1")]),
    radix_tabs_trigger("tab2", children=[@luna.text("Tab 2")]),
  ]),
  radix_tabs_content("tab1", children=[@luna.text("Content 1")]),
  radix_tabs_content("tab2", children=[@luna.text("Content 2")]),
])
```

### Tag

Label tag with variants.

```moonbit
radix_tag(variant=Primary, size=Md, children=[@luna.text("Featured")])
```

### Textarea

Multi-line text input.

```moonbit
radix_textarea(placeholder="Enter description...", rows=4)
```

### TimePicker

Time selection.

```moonbit
radix_time_picker(open=true, children=[
  radix_time_picker_trigger(value="14:30", children=[...]),
  radix_time_picker_content(children=[
    radix_time_picker_column("hours", children=[
      radix_time_picker_option("14", selected=true),
    ]),
    radix_time_picker_separator(),
    radix_time_picker_column("minutes", children=[
      radix_time_picker_option("30", selected=true),
    ]),
  ]),
])
```

### Timeline

Vertical timeline.

```moonbit
radix_timeline(children=[
  radix_timeline_item(children=[
    radix_timeline_dot(),
    radix_timeline_connector(),
    radix_timeline_content(children=[
      radix_timeline_title(children=[@luna.text("Event 1")]),
      radix_timeline_description(children=[@luna.text("Description...")]),
    ]),
  ]),
])
```

### Toast

Toast notification.

```moonbit
radix_toast(variant=Success, open=true, children=[
  radix_toast_title(children=[@luna.text("Success!")]),
  radix_toast_description(children=[@luna.text("Your changes were saved.")]),
  radix_toast_close(),
])
```

### Toggle

Toggle button.

```moonbit
radix_toggle(pressed=true, children=[@luna.text("Bold")])
```

### ToggleGroup

Group of toggle buttons.

```moonbit
radix_toggle_group(group_type=Single, children=[
  radix_toggle_group_item("left", pressed=true, children=[@luna.text("L")]),
  radix_toggle_group_item("center", children=[@luna.text("C")]),
  radix_toggle_group_item("right", children=[@luna.text("R")]),
])
```

### Toolbar

Toolbar container.

```moonbit
radix_toolbar(children=[
  radix_toolbar_button(children=[@luna.text("Bold")]),
  radix_toolbar_separator(),
  radix_toolbar_toggle_group(children=[...]),
])
```

### Tooltip

Hover tooltip.

```moonbit
radix_tooltip(children=[
  radix_tooltip_trigger(children=[@luna.text("Hover me")]),
  radix_tooltip_content(children=[@luna.text("Tooltip text")]),
])
```

### Tree

Tree view.

```moonbit
radix_tree(children=[
  radix_tree_item(expanded=true, children=[
    radix_tree_item_trigger(children=[@luna.text("Folder")]),
    radix_tree_item_content(children=[
      radix_tree_item(children=[
        radix_tree_item_trigger(children=[@luna.text("File.txt")]),
      ]),
    ]),
  ]),
])
```
