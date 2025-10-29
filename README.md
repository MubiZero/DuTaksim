# DuTaksim - Умное деление счетов

**DuTaksim** (ду таксим - "делить пополам" на таджикском) - современное мобильное приложение для деления счетов в ресторанах и кафе.

> Разработано для конкурса ИИ приложений Банк Эсхата

## ✨ Основные возможности

### 🏠 Создать комнату
- Генерация QR-кода для быстрого присоединения
- GPS-обнаружение (радиус 50м) для поиска активных сессий
- Live-обновления - все видят что добавляют другие
- Каждый участник добавляет свои позиции сам

### 📱 Умное деление
- Индивидуальные позиции (только для одного человека)
- Общие позиции (делятся поровну)
- Автоматический учёт чаевых
- Оптимизация долгов (минимум транзакций)

### 📸 Удобный ввод
- OCR сканирование чеков (Google ML Kit)
- Ручной ввод позиций
- Выбор участников из контактов
- QR-код для оплаты через Банк Эсхата

### 📊 История и статистика
- Все счета и долги в одном месте
- Кому должны вы
- Кто должен вам
- Детали каждого счета

---

## 🚀 Быстрый старт

### Требования
- Flutter SDK 3.35.3+
- Node.js 18+
- PostgreSQL 14+

### Backend Setup

1. **Установка:**
```bash
cd dutaksim_backend
npm install
```

2. **Настройка .env:**
```env
DB_HOST=your_database_host
DB_PORT=5432
DB_NAME=dutaksim
DB_USER=postgres
DB_PASSWORD=your_password
PORT=3000
```

3. **База данных:**
```bash
# Первая установка
npm run setup

# Или миграция для существующей БД
npm run migrate
```

4. **Запуск:**
```bash
npm start
# Backend running on http://localhost:3000
```

### Flutter App Setup

1. **Установка зависимостей:**
```bash
cd dutaksim_app
flutter pub get
```

2. **Настройка constants.dart:**
```dart
// lib/config/constants.dart
static const String baseUrl = 'http://your_server_ip:3000/api';
```

3. **Запуск:**
```bash
# Android/iOS
flutter run

# Web
flutter run -d chrome
```

---

## 🏗️ Технологический стек

### Frontend
- **Flutter** - кросс-платформа (iOS, Android, Web)
- **Riverpod** - state management
- **go_router** - навигация
- **Google ML Kit** - OCR
- **mobile_scanner** - QR-сканер
- **geolocator** - GPS
- **contacts_service** - контакты

### Backend
- **Node.js + Express** - REST API
- **PostgreSQL** - база данных
- **dotenv** - конфигурация

---

## 📂 Структура проекта

```
EasyDinner/
├── dutaksim_app/           # Flutter приложение
│   ├── lib/
│   │   ├── config/         # Тема и константы
│   │   ├── models/         # Модели данных
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI экраны
│   │   ├── services/       # API сервисы
│   │   └── utils/          # Утилиты
│   └── pubspec.yaml
│
├── dutaksim_backend/       # Node.js Backend
│   ├── routes/             # API endpoints
│   │   ├── users.js        # Пользователи
│   │   ├── bills.js        # Счета
│   │   ├── sessions.js     # Сессии (NEW!)
│   │   └── contacts.js     # Контакты (NEW!)
│   ├── utils/              # Утилиты
│   ├── config/             # Конфигурация БД
│   ├── migrations/         # SQL миграции
│   └── server.js
│
├── README.md               # Этот файл
└── ARCHITECTURE.md         # Архитектура системы
```

---

## 🎯 Основные сценарии использования

### Сценарий 1: Обед с коллегами

1. Один человек создает "комнату" → показывает QR
2. Коллеги сканируют QR или находят через GPS
3. Каждый добавляет что заказал
4. Создатель жмет "Финализировать" → автоматически считаются долги
5. Все видят сколько кому должны
6. Оплата через QR-код Банк Эсхата

### Сценарий 2: Быстрое деление вдвоем

1. Создать обычный счет
2. Добавить друга по номеру
3. Указать кто что брал
4. Чаевые делятся автоматически
5. Готово!

---

## 🔐 Разрешения (Android/iOS)

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Для сканирования QR-кодов и чеков</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Для поиска активных сессий поблизости</string>
<key>NSContactsUsageDescription</key>
<string>Для выбора участников из контактов</string>
```

---

## 🔧 API Endpoints

### Users
- `POST /api/users/register` - Регистрация
- `GET /api/users/phone/:phone` - Поиск по телефону
- `GET /api/users/:id/stats` - Статистика пользователя

### Bills
- `POST /api/bills` - Создать счет
- `GET /api/bills/user/:userId` - Счета пользователя
- `GET /api/bills/:id` - Детали счета
- `PATCH /api/bills/debts/:debtId/pay` - Отметить оплату

### Sessions (Collaborative)
- `POST /api/sessions/create` - Создать сессию
- `GET /api/sessions/nearby` - Найти поблизости
- `POST /api/sessions/join` - Присоединиться
- `GET /api/sessions/:id` - Детали сессии
- `POST /api/sessions/:id/items` - Добавить позицию
- `POST /api/sessions/:id/finalize` - Создать счет

### Contacts
- `POST /api/contacts/lookup` - Проверить контакты
- `POST /api/contacts/sessions/:id/add-participants` - Добавить участников

---

## 🎨 Дизайн

### Цветовая палитра (Банк Эсхата)
- **Primary:** `rgb(0, 80, 200)` - Синий
- **Secondary:** `rgb(145, 190, 235)` - Светло-синий
- **Accent:** `rgb(255, 205, 170)` - Персиковый
- **Background:** `rgb(255, 255, 255)` - Белый

### Шрифт
- **Google Fonts Inter** - современный, читаемый

---

## 🐛 Troubleshooting

### Backend не запускается
```bash
# Проверьте PostgreSQL
sudo systemctl status postgresql

# Проверьте .env файл
cat .env

# Проверьте подключение к БД
psql -U postgres -d dutaksim
```

### Flutter ошибки компиляции
```bash
# Очистите кэш
flutter clean
flutter pub get

# Обновите зависимости
flutter pub upgrade
```

### Нет GPS или контактов
- Проверьте разрешения в настройках устройства
- На эмуляторе установите mock location
- Для контактов используйте физическое устройство

---

## 📖 Дополнительная документация

См. [ARCHITECTURE.md](./ARCHITECTURE.md) для подробной архитектуры системы.

---

## 👥 Команда

**DuTaksim Team** - для конкурса Банк Эсхата 2025

---

## 📄 Лицензия

Proprietary - разработано для конкурса Банк Эсхата

---

**Версия:** 2.0.0
**Последнее обновление:** Октябрь 2025
