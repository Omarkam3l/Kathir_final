# Localization Guide

This project uses `flutter_localizations` and `.arb` files for internationalization.

## How to add new localized strings

1.  **Add the key to `app_en.arb`** (English):
    ```json
    "newKey": "New localized string",
    "@newKey": {
      "description": "Description of where this string is used"
    }
    ```

2.  **Add the key to `app_ar.arb`** (Arabic):
    ```json
    "newKey": "سلسلة مترجمة جديدة"
    ```

3.  **Use it in your code**:
    ```dart
    final l10n = AppLocalizations.of(context)!;
    Text(l10n.newKey);
    ```

## Handling Dynamic Content (Parameters)

If you need to include dynamic values (like numbers or names) inside a localized string, use placeholders.

**In `app_en.arb`:**
```json
"welcomeUser": "Welcome, {userName}!",
"@welcomeUser": {
  "placeholders": {
    "userName": {
      "type": "String"
    }
  }
}
```

**In `app_ar.arb`:**
```json
"welcomeUser": "مرحباً، {userName}!"
```

**Usage:**
```dart
Text(l10n.welcomeUser(user.name));
```

## Future Screens and Components

When adding new screens:
1.  **Do not hardcode strings.** Always add them to the ARB files first.
2.  **Use `AppLocalizations.of(context)!`** at the top of your `build` method.
3.  **For dynamic data** (like from an API), ensure your backend supports multiple languages or use parameterized strings to format the data correctly (e.g., `l10n.price(amount)`).
