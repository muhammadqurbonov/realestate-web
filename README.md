# Realestate App (multi-tenant)

Барномаи мобилии феҳристи амволи ғайриманқул барои якчанд ширкат (агентигиҳо),
бо забони тоҷикӣ ва русӣ.

## Сохтори лоиҳа

```
lib/
  models/
    app_user.dart       — корбар (superAdmin / admin / manager) + companyId
    property.dart        — Property (оммавӣ) + PropertyPrivateInfo (хусусӣ)
    client.dart           — талаботи муштарӣ
  services/
    auth_service.dart     — воридшавӣ, сохтани ҳисоби менеҷер/админ
    firestore_service.dart — CRUD барои хона ва муштарӣ + мувофиқасозӣ
    storage_service.dart   — боркунии акс/видео ба Firebase Storage
    locale_service.dart    — интихоби забон (ТҶ/РУ), захира дар дастгоҳ
  l10n/
    app_strings.dart      — матнҳои барнома ба ду забон
  screens/
    login_screen.dart
    main_menu_screen.dart     — менюи асосӣ (5 тугма)
    add_property_screen.dart  — иловаи хона + акс/видео + комиссия
    my_properties_screen.dart
    all_properties_screen.dart
    clients_screen.dart       — муштариён + мувофиқасозии худкор
    settings_screen.dart      — забон, иловаи менеҷер/админ (role-based)
  widgets/
    property_card.dart
  main.dart              — нуқтаи оғоз, Firebase + Provider

firestore.rules          — Security Rules (маҳфияти рақами соҳибхона)
storage.rules            — Security Rules барои акс/видео
```

## Мантиқи маҳфият (муҳимтарин қисм)

Ҳар хона дар ДУ ҳуҷҷат нигоҳ дошта мешавад:

- `properties/{id}` — маълумоти оммавӣ (суроға, аксҳо, **managerPrice**)
- `properties/{id}/private/contact` — маълумоти хусусӣ (рақами соҳибхона,
  нархи аслии ӯ, навъи комиссия) — танҳо менеҷери иловакунанда ё
  админ/суперадмини ҳамон ширкат тавассути `firestore.rules` дастрасӣ дорад

## Оғози кор

1. Насб кардани Flutter SDK (агар набошад): https://docs.flutter.dev/get-started/install
2. Дар терминал:
   ```
   flutter pub get
   ```
3. Сохтани лоиҳаи Firebase дар https://console.firebase.google.com
   - Фаъол кардани **Authentication** (Email/Password)
   - Фаъол кардани **Firestore Database**
   - Фаъол кардани **Storage**
4. Насби FlutterFire CLI ва пайваст кардани лоиҳа:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Ин фармон файли `lib/firebase_options.dart`-ро месозад — баъд дар
   `main.dart` бояд `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
   истифода баред.
5. Боргузории қоидаҳо:
   ```
   firebase deploy --only firestore:rules,storage:rules
   ```
6. Сохтани корбари АВВАЛИН (шумо — суперадмин) — ин корро аз Firebase
   Console дастӣ кунед: як корбар дар Authentication созед, баъд дар
   Firestore коллексияи `users/{uid}` бо дасти худ ҳуҷҷат созед:
   ```
   {
     "fullName": "Шумо",
     "phone": "+992...",
     "role": "superAdmin",
     "companyId": "your-company-id"
   }
   ```
   Пас аз ин, шумо метавонед аз дохили барнома (Танзимот → Иловаи менеҷер)
   менеҷерону админҳои дигарро илова кунед.
7. Иҷрои барнома:
   ```
   flutter run
   ```

## Қадамҳои навбатӣ (пешниҳод)

- Экрани деталии хона (бо галереяи аксҳо/видео ва рақами соҳибхона
  барои соҳиби эълон)
- Push-уведомление ба менеҷер вақте ки муштарии нав ба хонаи ӯ мувофиқ ояд
  (тавассути Cloud Function)
- Ҷустуҷӯ ва филтр дар "Ҳамаи хонаҳо" (нарх, минтақа, шумораи ҳуҷра)
- Марҳилаи "фурӯхта шуд" барои хона (майдони `isSold` аллакай омода аст)
