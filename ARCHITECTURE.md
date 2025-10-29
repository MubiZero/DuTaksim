# DuTaksim - Архитектура системы

## Обзор

DuTaksim - полнофункциональное приложение для деления счетов с collaborative функциями реального времени. Архитектура построена на принципах Clean Architecture с разделением на слои.

---

## 🏛️ Высокоуровневая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Client)                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Screens   │  │  Providers  │  │   Models    │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                 │                 │            │
│         └─────────────────┼─────────────────┘            │
│                           │                              │
│                  ┌────────▼────────┐                     │
│                  │  API Service    │                     │
│                  └────────┬────────┘                     │
└───────────────────────────┼──────────────────────────────┘
                            │ HTTP/REST
                            │
┌───────────────────────────▼──────────────────────────────┐
│                 Node.js Backend (Server)                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Routes    │  │    Utils    │  │   Config    │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                 │                 │            │
│         └─────────────────┼─────────────────┘            │
│                           │                              │
│                  ┌────────▼────────┐                     │
│                  │  PostgreSQL     │                     │
│                  └─────────────────┘                     │
└──────────────────────────────────────────────────────────┘
```

---

## 📱 Frontend Architecture (Flutter)

### Структура слоев

```
lib/
├── config/                 # Конфигурация приложения
│   ├── theme.dart         # Material Theme, цвета
│   └── constants.dart     # API URL, константы
│
├── models/                 # Модели данных (Data Layer)
│   ├── user.dart          # User entity
│   ├── bill.dart          # Bill entity
│   ├── session.dart       # Session entity (NEW!)
│   └── ...
│
├── services/              # Сервисы (Service Layer)
│   ├── api_service.dart   # HTTP клиент (Dio)
│   └── storage_service.dart # Local storage
│
├── providers/             # State Management (Business Logic)
│   ├── user_provider.dart
│   ├── bill_provider.dart
│   └── session_provider.dart (NEW!)
│
├── screens/               # UI Layer
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── session_screen.dart (NEW!)
│   └── ...
│
├── utils/                 # Утилиты
│   └── qr_generator.dart
│
└── main.dart             # Entry point + Routing
```

### State Management (Riverpod)

**Принцип:** Unidirectional data flow

```
User Action → Provider → API Service → Backend
                ↓
            State Update
                ↓
            UI Rebuild
```

**Примеры:**

```dart
// Provider с auto-refresh
final sessionNotifierProvider = StateNotifierProvider<SessionNotifier, AsyncValue<BillSession?>>((ref) {
  return SessionNotifier(ref.watch(apiServiceProvider));
});

// Consumer в UI
ref.watch(sessionNotifierProvider).when(
  data: (session) => SessionWidget(session),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => ErrorWidget(err),
);
```

### Навигация (GoRouter)

**Declarative routing:**

```dart
GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => MainNavigationScreen()),
    GoRoute(path: '/session', builder: (_, __) => SessionScreen()),
    GoRoute(path: '/bill/:id', builder: (_, state) => BillDetailScreen(id: state.params['id'])),
  ],
  redirect: (_, state) {
    final user = ref.read(currentUserProvider);
    if (user == null && state.location != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
);
```

---

## 🖥️ Backend Architecture (Node.js)

### Структура

```
dutaksim_backend/
├── routes/                 # API Routes (Controller Layer)
│   ├── users.js           # User management
│   ├── bills.js           # Bill CRUD
│   ├── sessions.js        # Collaborative sessions (NEW!)
│   ├── contacts.js        # Contact management (NEW!)
│   └── transactions.js    # Transaction queries
│
├── utils/                 # Business Logic
│   └── debtCalculator.js  # Debt optimization algorithm
│
├── config/                # Configuration
│   └── database.js        # PostgreSQL connection pool
│
├── migrations/            # Database Migrations
│   └── add_sessions.sql   # Sessions tables (NEW!)
│
├── database.sql           # Complete DB schema
├── server.js             # Express app entry point
└── .env                  # Environment variables
```

### API Endpoints Structure

**Паттерн:** RESTful API

```javascript
// routes/sessions.js
router.post('/create', async (req, res) => {
  // 1. Validate input
  // 2. Begin transaction
  // 3. Generate unique session code
  // 4. Insert session
  // 5. Add creator as participant
  // 6. Commit transaction
  // 7. Return full session object
});

router.get('/nearby', async (req, res) => {
  // 1. Get coordinates from query
  // 2. Query active sessions
  // 3. Calculate distances (Haversine)
  // 4. Filter by radius
  // 5. Return sorted list
});
```

### Обработка ошибок

```javascript
try {
  await client.query('BEGIN');
  // ... operations
  await client.query('COMMIT');
  res.json(result);
} catch (error) {
  await client.query('ROLLBACK');
  console.error('Error:', error);
  res.status(500).json({ error: 'Operation failed' });
} finally {
  client.release();
}
```

---

## 🗄️ Database Architecture (PostgreSQL)

### Entity Relationship Diagram

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   users     │◄────────┤    bills     │────────►│bill_items   │
│             │         │              │         │             │
│ - id        │         │ - id         │         │ - id        │
│ - name      │         │ - paid_by    │         │ - bill_id   │
│ - phone     │         │ - total      │         │ - name      │
└──────┬──────┘         │ - tips       │         │ - price     │
       │                └──────┬───────┘         │ - is_shared │
       │                       │                 └──────┬──────┘
       │                       │                        │
       │           ┌───────────┴────────────┐          │
       │           │                        │          │
       │      ┌────▼────────┐         ┌────▼──────────▼─────┐
       │      │bill_parti-  │         │item_participants     │
       │      │cipants      │         │                      │
       └──────┤             │         │ - item_id            │
              │ - bill_id   │         │ - user_id            │
              │ - user_id   │         └──────────────────────┘
              └─────┬───────┘
                    │
              ┌─────▼───────┐
              │   debts     │
              │             │
              │ - bill_id   │
              │ - debtor_id │
              │ - creditor  │
              │ - amount    │
              │ - is_paid   │
              └─────────────┘

┌─────────────────────┐
│  bill_sessions      │◄───┐
│                     │    │
│ - id                │    │
│ - session_code      │    │
│ - name              │    │
│ - creator_id        │    │
│ - latitude          │    │
│ - longitude         │    │
│ - status            │    │
│ - bill_id (FK)      │    │
└──────┬──────────────┘    │
       │                   │
       ├───────────────────┤
       │                   │
  ┌────▼────────┐    ┌────▼──────────┐
  │session_     │    │session_items  │
  │participants │    │               │
  │             │    │ - session_id  │
  │ - session_id│    │ - added_by    │
  │ - user_id   │    │ - name        │
  │ - role      │    │ - price       │
  └─────────────┘    │ - for_user_id │
                     │ - is_shared   │
                     └───────────────┘
```

### Индексы для производительности

```sql
-- Быстрый поиск счетов пользователя
CREATE INDEX idx_bills_paid_by ON bills(paid_by);
CREATE INDEX idx_bill_participants_user_id ON bill_participants(user_id);

-- Быстрый поиск долгов
CREATE INDEX idx_debts_debtor_id ON debts(debtor_id);
CREATE INDEX idx_debts_creditor_id ON debts(creditor_id);

-- GPS поиск (NEW!)
CREATE INDEX idx_bill_sessions_location ON bill_sessions(latitude, longitude)
WHERE status = 'active';

-- Очистка устаревших сессий
CREATE INDEX idx_bill_sessions_expires ON bill_sessions(expires_at);
```

### Транзакции

**Критические операции в транзакциях:**

```sql
BEGIN;
  -- 1. Create bill
  INSERT INTO bills ...;

  -- 2. Add participants
  INSERT INTO bill_participants ...;

  -- 3. Add items
  INSERT INTO bill_items ...;

  -- 4. Calculate debts
  INSERT INTO debts ...;
COMMIT;
```

---

## 🔄 Collaborative Sessions Flow

### Архитектура real-time (polling)

```
User A                    Backend                    User B
  │                         │                          │
  │──► Create Session       │                          │
  │◄── Session + QR Code    │                          │
  │                         │                          │
  │                         │◄─── Scan QR / Join      │
  │                         │──── Session Details ────►│
  │                         │                          │
  │──► Add Item             │                          │
  │     (auto-refresh)      │                          │
  │                         │      (polling 5s)        │
  │                         │◄─── Refresh Session ────│
  │                         │──── Updated Items ──────►│
  │                         │                          │
  │──► Finalize Session     │                          │
  │◄── Bill Created         │                          │
  │                         │──── Bill Created ───────►│
```

### Polling vs WebSockets

**Решение:** Используем polling (каждые 5 секунд)

**Почему polling?**
- ✅ Проще реализация
- ✅ Меньше нагрузка на сервер
- ✅ Работает через прокси/firewall
- ✅ Достаточно для use case (не требуется instant updates)

**Минусы WebSockets в данном случае:**
- ❌ Сложнее масштабирование
- ❌ Проблемы с мобильными сетями
- ❌ Требуется дополнительный сервер (Socket.io)

### Session Lifecycle

```
1. ACTIVE
   ↓ (expires_at reached OR manual close)
2. CLOSED
   ↓ (creator finalizes)
3. FINALIZED
   ↓ (bill_id set)
   ↓
   Bill created in bills table
```

---

## 🧮 Debt Calculation Algorithm

### Принцип

Минимизация транзакций через debt optimization.

### Алгоритм

```javascript
// Шаг 1: Рассчитать сколько каждый человек должен заплатить
for each item:
  if item.is_shared:
    cost_per_person = item.price / participant_count
    for each participant:
      balance[participant] -= cost_per_person
  else:
    balance[item.for_user_id] -= item.price

// Шаг 2: Добавить чаевые (делятся поровну)
tips_per_person = tips / participant_count
for each participant:
  balance[participant] -= tips_per_person

// Шаг 3: Учесть кто заплатил
balance[paidBy] += totalAmount + tips

// Шаг 4: Создать долги
for each participant (except paidBy):
  if balance[participant] < 0:
    CREATE DEBT {
      debtor_id: participant,
      creditor_id: paidBy,
      amount: abs(balance[participant])
    }
```

### Пример

```
Bill: 300 сомони + 30 чаевых = 330 сомони
Participants: Alice, Bob, Charlie
Alice заплатила

Items:
- Пицца 150 (shared by all)
- Салат 100 (only Bob)
- Десерт 50 (shared by all)

Calculation:
Alice:  -50 (pizza) - 16.67 (desert) - 10 (tips) + 330 (paid) = +253.33
Bob:    -50 (pizza) - 100 (salad) - 16.67 (desert) - 10 (tips) = -176.67
Charlie: -50 (pizza) - 16.67 (desert) - 10 (tips) = -76.67

Debts:
Bob → Alice: 176.67 сомони
Charlie → Alice: 76.67 сомони
```

---

## 🌍 GPS & Geolocation

### Haversine Formula

Расчет расстояния между двумя точками на сфере:

```javascript
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // meters
}
```

### Оптимизация

1. **Индекс:** `idx_bill_sessions_location` на `(latitude, longitude)`
2. **Фильтр:** `WHERE status = 'active'` (только активные)
3. **In-memory filter:** Сначала выбираем из БД, потом фильтруем по расстоянию

---

## 🔐 Security Considerations

### Authentication

**Упрощенная схема (для конкурса):**
- Только имя + телефон
- Нет паролей
- Хранение userId в SharedPreferences

**Для production:**
- ❌ Добавить JWT tokens
- ❌ Добавить OTP верификацию
- ❌ Rate limiting на API

### API Security

**Текущая реализация:**
```javascript
app.use(cors()); // Открыт для всех
```

**Для production:**
```javascript
app.use(cors({
  origin: ['https://yourdomain.com'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use('/api/', limiter);
```

### SQL Injection Protection

✅ Используем parameterized queries:
```javascript
// ✅ SAFE
client.query('SELECT * FROM users WHERE phone = $1', [phone]);

// ❌ UNSAFE (не используем)
client.query(`SELECT * FROM users WHERE phone = '${phone}'`);
```

---

## 📈 Scalability Considerations

### Current Architecture

- **Concurrent users:** ~100-500
- **Database:** Single PostgreSQL instance
- **Backend:** Single Node.js process

### Scaling Strategy (Future)

1. **Horizontal Scaling:**
```
Load Balancer
     ↓
┌────┴────┬────────┬────────┐
│ Node 1  │ Node 2 │ Node 3 │
└────┬────┴────┬───┴────┬───┘
     └─────────┼────────┘
               ↓
         PostgreSQL
```

2. **Database Scaling:**
- Read replicas для GET запросов
- Connection pooling (уже реализован через `pg.Pool`)
- Caching (Redis) для часто используемых данных

3. **Sessions Cleanup:**
```javascript
// Cron job to delete expired sessions
setInterval(async () => {
  await pool.query(`
    DELETE FROM bill_sessions
    WHERE expires_at < NOW() - INTERVAL '1 day'
  `);
}, 3600000); // Every hour
```

---

## 🧪 Testing Strategy

### Backend Tests (Recommended)

```javascript
// Jest tests
describe('Session Creation', () => {
  test('should create session with valid data', async () => {
    const response = await request(app)
      .post('/api/sessions/create')
      .send({ name: 'Test', creatorId: 'uuid' });

    expect(response.status).toBe(200);
    expect(response.body.session_code).toHaveLength(6);
  });
});
```

### Flutter Tests (Recommended)

```dart
// Widget tests
testWidgets('Session screen shows items', (tester) async {
  await tester.pumpWidget(ProviderScope(
    child: SessionScreen(),
  ));

  expect(find.text('Collaborative Session'), findsOneWidget);
});
```

---

## 📊 Performance Metrics

### Expected Response Times

- User registration: <200ms
- Bill creation: <500ms
- Session creation: <300ms
- Nearby sessions query: <150ms
- Session refresh: <100ms

### Database Query Optimization

```sql
-- Explain analyze для проверки
EXPLAIN ANALYZE
SELECT * FROM bill_sessions
WHERE status = 'active'
AND expires_at > NOW();

-- Должно использовать idx_bill_sessions_status
```

---

## 🚀 Deployment Architecture

### Production Setup

```
┌──────────────────────────────────────────┐
│              NGINX (Reverse Proxy)        │
│         SSL/TLS Termination               │
└─────────────┬────────────────────────────┘
              │
     ┌────────┴────────┐
     │                 │
┌────▼─────┐    ┌─────▼────┐
│ Static   │    │ Node.js  │
│ Flutter  │    │ Backend  │
│ Web App  │    │ :3000    │
└──────────┘    └────┬─────┘
                     │
              ┌──────▼──────┐
              │ PostgreSQL  │
              │   :5432     │
              └─────────────┘
```

### Environment Variables

```env
# Production
NODE_ENV=production
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dutaksim_prod
DB_USER=dutaksim_user
DB_PASSWORD=<secure_password>
PORT=3000

# Enable SSL for PostgreSQL
DB_SSL=true
```

---

## 📝 Summary

**DuTaksim Architecture Features:**

✅ **Clean Architecture** - разделение на слои
✅ **RESTful API** - стандартизированные endpoints
✅ **State Management** - Riverpod для Flutter
✅ **Real-time Collaboration** - через polling (5s)
✅ **Optimized Database** - индексы для быстрых запросов
✅ **Debt Optimization** - минимум транзакций
✅ **Scalable Design** - готовность к горизонтальному масштабированию
✅ **Security** - parameterized queries, input validation

---

**Версия:** 2.0.0
**Последнее обновление:** Октябрь 2025
