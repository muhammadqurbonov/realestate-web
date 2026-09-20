/// Оддитарин системаи забон (localization) — на ба intl/arb вобаста аст.
/// Ду забон дастгирӣ мешавад: тоҷикӣ (tj) ва русӣ (ru).
library;

enum AppLocale { tj, ru }

class AppStrings {
  final AppLocale locale;
  AppStrings(this.locale);

  static const Map<String, Map<AppLocale, String>> _values = {
    // Меню
    'menu_title': {AppLocale.tj: 'Хонаҳо', AppLocale.ru: 'Недвижимость'},
    'add_property': {AppLocale.tj: 'Иловаи хонаҳо', AppLocale.ru: 'Добавить объект'},
    'my_properties': {AppLocale.tj: 'Хонаҳои ман', AppLocale.ru: 'Мои объекты'},
    'all_properties': {AppLocale.tj: 'Ҳамаи хонаҳо', AppLocale.ru: 'Все объекты'},
    'clients': {AppLocale.tj: 'Муштариён', AppLocale.ru: 'Клиенты'},
    'settings': {AppLocale.tj: 'Танзимот', AppLocale.ru: 'Настройки'},

    // Воридшавӣ / сабти ном
    'login': {AppLocale.tj: 'Воридшавӣ', AppLocale.ru: 'Вход'},
    'phone': {AppLocale.tj: 'Рақами телефон', AppLocale.ru: 'Номер телефона'},
    'password': {AppLocale.tj: 'Рамз', AppLocale.ru: 'Пароль'},
    'login_button': {AppLocale.tj: 'Ворид шудан', AppLocale.ru: 'Войти'},
    'email': {AppLocale.tj: 'Email (Gmail)', AppLocale.ru: 'Email (Gmail)'},
    'forgot_password': {AppLocale.tj: 'Парол фаромӯш шуд?', AppLocale.ru: 'Забыли пароль?'},
    'reset_password_title': {AppLocale.tj: 'Барқарорсозии рамз', AppLocale.ru: 'Восстановление пароля'},
    'reset_password_desc': {
      AppLocale.tj: 'Email-и худро нависед — линки барқарорсозӣ фиристода мешавад',
      AppLocale.ru: 'Введите email — ссылка для восстановления будет отправлена',
    },
    'reset_password_sent': {
      AppLocale.tj: 'Паём фиристода шуд — почтаи худро санҷед',
      AppLocale.ru: 'Письмо отправлено — проверьте почту',
    },
    'send': {AppLocale.tj: 'Фиристодан', AppLocale.ru: 'Отправить'},
    'no_account_register': {AppLocale.tj: 'Ҳисоб надоред? Сабти ном', AppLocale.ru: 'Нет аккаунта? Регистрация'},
    'have_account_login': {AppLocale.tj: 'Ҳисоб доред? Воридшавӣ', AppLocale.ru: 'Есть аккаунт? Войти'},
    'register_title': {AppLocale.tj: 'Сабти номи менеҷер', AppLocale.ru: 'Регистрация менеджера'},
    'full_name': {AppLocale.tj: 'Номи пурра', AppLocale.ru: 'Полное имя'},
    'company_code': {AppLocale.tj: 'Рамзи ширкат', AppLocale.ru: 'Код компании'},
    'company_code_hint': {
      AppLocale.tj: 'Аз суперадмини ширкати худ гиред',
      AppLocale.ru: 'Получите у суперадмина вашей компании',
    },
    'register_button': {AppLocale.tj: 'Сабти ном', AppLocale.ru: 'Зарегистрироваться'},
    'promote_to_admin': {AppLocale.tj: 'Кардан ба админ', AppLocale.ru: 'Сделать админом'},

    // Қадами 0 — категория
    'step_category_title': {
      AppLocale.tj: 'Кадом навъи эълонро мехоҳед созед?',
      AppLocale.ru: 'Какой тип объявления хотите создать?',
    },
    'category_apartment': {AppLocale.tj: 'Фуруши хонаҳо', AppLocale.ru: 'Продажа квартир'},
    'category_house_land': {AppLocale.tj: 'Фуруши ҳавлӣ ва дача', AppLocale.ru: 'Продажа дома и дачи'},

    'step_houseland_type_title': {AppLocale.tj: 'Ин чист?', AppLocale.ru: 'Что это?'},
    'houseland_havli': {AppLocale.tj: 'Ҳавлӣ', AppLocale.ru: 'Дом с участком'},
    'houseland_dacha': {AppLocale.tj: 'Дача', AppLocale.ru: 'Дача'},

    'step_rooms_title': {AppLocale.tj: 'Чанд хонагӣ аст?', AppLocale.ru: 'Сколько комнат?'},
    'step_price_title': {AppLocale.tj: 'Нархи хона чанд аст?', AppLocale.ru: 'Какая цена объекта?'},
    'step_description_title': {AppLocale.tj: 'Тавсифи хона', AppLocale.ru: 'Описание объекта'},
    'step_description_hint': {
      AppLocale.tj: 'Дар бораи хона нависед...',
      AppLocale.ru: 'Напишите об объекте...',
    },
    'step_address_title': {AppLocale.tj: 'Суроғаи пурра', AppLocale.ru: 'Полный адрес'},
    'step_area_title': {AppLocale.tj: 'Масоҳат чанд метри мураббаъ аст?', AppLocale.ru: 'Какая площадь (м²)?'},
    'step_floor_title': {AppLocale.tj: 'Ошёна ва шумораи ошёнаҳои бино', AppLocale.ru: 'Этаж и этажность дома'},
    'floor_label': {AppLocale.tj: 'Ошёна', AppLocale.ru: 'Этаж'},
    'total_floors_label': {AppLocale.tj: 'Шумораи ошёнаҳои бино', AppLocale.ru: 'Этажность дома'},
    'step_house_floors_title': {
      AppLocale.tj: 'Хона чанд ошёна дорад?',
      AppLocale.ru: 'Сколько этажей в доме?',
    },
    'step_land_sotka_title': {
      AppLocale.tj: 'Замин чанд сотиқ аст?',
      AppLocale.ru: 'Сколько соток земли?',
    },

    'step_building_form_title': {AppLocale.tj: 'Шакли бино', AppLocale.ru: 'Тип здания'},
    'building_old': {AppLocale.tj: 'Пешина', AppLocale.ru: 'Старый фонд'},
    'building_new': {AppLocale.tj: 'Навсохт', AppLocale.ru: 'Новостройка'},

    'step_renovation_title': {AppLocale.tj: 'Ҳолати таъмир', AppLocale.ru: 'Состояние ремонта'},
    'renovation_fresh': {AppLocale.tj: 'Нав', AppLocale.ru: 'Новый ремонт'},
    'renovation_average': {AppLocale.tj: 'Миёна', AppLocale.ru: 'Средний'},
    'renovation_empty': {AppLocale.tj: 'Бетаъмир (қуттии холӣ)', AppLocale.ru: 'Без ремонта (коробка)'},

    'step_construction_status_title': {AppLocale.tj: 'Ҳолати бино', AppLocale.ru: 'Статус строительства'},
    'construction_built': {AppLocale.tj: 'Сохташуда', AppLocale.ru: 'Построен'},
    'construction_in_progress': {
      AppLocale.tj: 'Дар марҳилаи сохтмон',
      AppLocale.ru: 'В процессе строительства',
    },

    'step_bathroom_title': {AppLocale.tj: 'Ҳаммом ва ҳоҷатхона', AppLocale.ru: 'Санузел'},
    'bathroom_separate': {AppLocale.tj: 'Алоҳида', AppLocale.ru: 'Раздельный'},
    'bathroom_combined': {AppLocale.tj: 'Якҷоя', AppLocale.ru: 'Совмещённый'},

    'step_tech_passport_title': {AppLocale.tj: 'Техпаспорт ҳаст?', AppLocale.ru: 'Есть техпаспорт?'},
    'yes': {AppLocale.tj: 'Ҳаст', AppLocale.ru: 'Есть'},
    'no': {AppLocale.tj: 'Нест', AppLocale.ru: 'Нет'},

    'step_photos_title': {AppLocale.tj: 'Аксҳо илова кунед', AppLocale.ru: 'Добавьте фотографии'},
    'add_photo': {AppLocale.tj: 'Иловаи акс', AppLocale.ru: 'Добавить фото'},

    'step_owner_title': {AppLocale.tj: 'Маслиҳат бо соҳибхона', AppLocale.ru: 'Договорённость с владельцем'},
    'owner_phone': {AppLocale.tj: 'Рақами соҳибхона', AppLocale.ru: 'Телефон владельца'},
    'commission_type': {AppLocale.tj: 'Шарти соҳибхона', AppLocale.ru: 'Условие владельца'},
    'commission_percent': {
      AppLocale.tj: 'Фоиз мегирад (масалан 2%)',
      AppLocale.ru: 'Берёт процент (например 2%)',
    },
    'commission_margin': {
      AppLocale.tj: 'Маблағи собит мехоҳад, боқимонда — фоидаи шумо',
      AppLocale.ru: 'Хочет фикс. сумму, остальное — ваша прибыль',
    },
    'commission_value': {AppLocale.tj: 'Қимат', AppLocale.ru: 'Значение'},
    'private_note': {
      AppLocale.tj: 'Ин маълумот танҳо ба шумо намоён аст',
      AppLocale.ru: 'Эта информация видна только вам',
    },

    'continue_button': {AppLocale.tj: 'Давом', AppLocale.ru: 'Далее'},
    'back_button': {AppLocale.tj: 'Бозгашт', AppLocale.ru: 'Назад'},
    'save': {AppLocale.tj: 'Нигоҳ доштан', AppLocale.ru: 'Сохранить'},
    'added_by': {AppLocale.tj: 'Менеҷери иловакарда', AppLocale.ru: 'Добавил менеджер'},

    'somoni': {AppLocale.tj: 'сомонӣ', AppLocale.ru: 'сомони'},
    'required_field': {AppLocale.tj: 'Ин майдон ҳатмист', AppLocale.ru: 'Обязательное поле'},
    'add_manager': {AppLocale.tj: 'Иловаи менеҷер', AppLocale.ru: 'Добавить менеджера'},
    'language': {AppLocale.tj: 'Забон', AppLocale.ru: 'Язык'},
    'logout': {AppLocale.tj: 'Баромадан', AppLocale.ru: 'Выйти'},
    'property_rooms': {AppLocale.tj: 'ҳуҷра', AppLocale.ru: 'комн.'},

    // Ҷустуҷӯ ва филтр
    'search_hint': {AppLocale.tj: 'Ҷустуҷӯ аз рӯи суроға...', AppLocale.ru: 'Поиск по адресу...'},
    'filters': {AppLocale.tj: 'Филтрҳо', AppLocale.ru: 'Фильтры'},
    'filter_category': {AppLocale.tj: 'Категория', AppLocale.ru: 'Категория'},
    'filter_all': {AppLocale.tj: 'Ҳама', AppLocale.ru: 'Все'},
    'filter_price_range': {AppLocale.tj: 'Диапазони нарх', AppLocale.ru: 'Диапазон цены'},
    'filter_min': {AppLocale.tj: 'Аз', AppLocale.ru: 'От'},
    'filter_max': {AppLocale.tj: 'То', AppLocale.ru: 'До'},
    'filter_rooms': {AppLocale.tj: 'Шумораи ҳуҷраҳо', AppLocale.ru: 'Количество комнат'},
    'filter_apply': {AppLocale.tj: 'Татбиқ кардан', AppLocale.ru: 'Применить'},
    'filter_reset': {AppLocale.tj: 'Тоза кардан', AppLocale.ru: 'Сбросить'},
    'no_results': {AppLocale.tj: 'Ҳеҷ чиз ёфт нашуд', AppLocale.ru: 'Ничего не найдено'},

    // Фурӯхта шуд
    'sold_badge': {AppLocale.tj: 'ФУРӮХТА ШУД', AppLocale.ru: 'ПРОДАНО'},
    'mark_sold': {AppLocale.tj: 'Қайд кардан ҳамчун фурӯхташуда', AppLocale.ru: 'Отметить как продано'},
    'unmark_sold': {AppLocale.tj: 'Бозгардонидан ба фурӯш', AppLocale.ru: 'Вернуть в продажу'},
    'show_sold': {AppLocale.tj: 'Хонаҳои фурӯхташударо нишон диҳед', AppLocale.ru: 'Показывать проданные'},
  };

  String t(String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[locale] ?? entry[AppLocale.tj] ?? key;
  }
}
