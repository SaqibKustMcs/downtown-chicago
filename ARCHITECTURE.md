# Food Flow App - Architecture Documentation

## Overview
This app follows a **Clean Architecture** pattern with clear separation of concerns. Each module is self-contained with its own models, services, controllers, repositories, and data sources.

## Project Structure

```
lib/
├── core/                          # Core functionality shared across modules
│   ├── base/                      # Base classes and interfaces
│   │   ├── base_controller.dart
│   │   ├── base_datasource.dart
│   │   ├── base_repository.dart
│   │   └── base_service.dart
│   ├── firebase/                  # Firebase initialization and services
│   │   └── firebase_service.dart
│   ├── di/                        # Dependency Injection
│   │   └── dependency_injection.dart
│   ├── constants/                 # App constants
│   ├── network/                   # Network layer (Dio, interceptors)
│   ├── providers/                 # State management providers
│   ├── services/                  # Core services (storage, database)
│   ├── utils/                     # Utility functions
│   └── widgets/                   # Shared widgets
│
├── modules/                        # Feature modules
│   ├── auth/                      # Authentication module
│   │   ├── models/                # Domain models
│   │   │   └── user_model.dart
│   │   ├── datasources/           # Data sources (Remote & Local)
│   │   │   ├── auth_remote_datasource.dart
│   │   │   └── auth_local_datasource.dart
│   │   ├── repositories/          # Repository layer
│   │   │   └── auth_repository.dart
│   │   ├── services/              # Business logic
│   │   │   └── auth_service.dart
│   │   ├── controllers/           # UI controllers (State management)
│   │   │   └── auth_controller.dart
│   │   ├── views/                 # UI screens
│   │   └── widgets/               # Module-specific widgets
│   │
│   ├── home/                      # Home module
│   │   ├── models/
│   │   │   ├── category_model.dart
│   │   │   ├── restaurant_model.dart
│   │   │   └── food_item_model.dart
│   │   ├── datasources/
│   │   │   ├── home_remote_datasource.dart
│   │   │   └── home_local_datasource.dart
│   │   ├── repositories/
│   │   │   ├── category_repository.dart
│   │   │   ├── restaurant_repository.dart
│   │   │   └── food_item_repository.dart
│   │   ├── services/
│   │   │   ├── category_service.dart
│   │   │   ├── restaurant_service.dart
│   │   │   └── food_item_service.dart
│   │   ├── controllers/
│   │   │   ├── home_controller.dart
│   │   │   ├── category_controller.dart
│   │   │   └── restaurant_controller.dart
│   │   └── views/
│   │
│   ├── orders/                    # Orders module
│   ├── checkout/                  # Cart & Checkout module
│   ├── profile/                   # Profile module
│   └── ...
│
├── models/                        # Shared models (legacy - will be migrated)
├── routes/                        # Routing configuration
└── styles/                        # App styling
```

## Architecture Layers

### 1. **Models Layer**
- Domain models representing business entities
- Firestore-compatible with `fromFirestore()` and `toFirestore()` methods
- Located in `modules/{module}/models/`

### 2. **Data Sources Layer**
- **Remote DataSource**: Firebase Firestore, REST APIs
- **Local DataSource**: SQLite, SharedPreferences, Secure Storage
- Implements `BaseDataSource` interface
- Located in `modules/{module}/datasources/`

### 3. **Repository Layer**
- Abstracts data sources
- Handles data transformation (Firestore → Model)
- Implements caching and offline support
- Implements `BaseRepository` interface
- Located in `modules/{module}/repositories/`

### 4. **Service Layer**
- Business logic and use cases
- Extends `BaseService`
- Located in `modules/{module}/services/`

### 5. **Controller Layer**
- UI state management
- Extends `BaseController` (ChangeNotifier)
- Handles loading states, errors
- Located in `modules/{module}/controllers/`

### 6. **View Layer**
- UI screens and widgets
- Consumes controllers via Provider/ChangeNotifier
- Located in `modules/{module}/views/` and `modules/{module}/widgets/`

## Module Structure Template

Each module should follow this structure:

```
module_name/
├── models/
│   └── {entity}_model.dart
├── datasources/
│   ├── {module}_remote_datasource.dart
│   └── {module}_local_datasource.dart
├── repositories/
│   └── {module}_repository.dart
├── services/
│   └── {module}_service.dart
├── controllers/
│   └── {module}_controller.dart
├── views/
│   └── {module}_screen.dart
└── widgets/
    └── {module}_widget.dart
```

## Dependency Flow

```
View → Controller → Service → Repository → DataSource → Firebase/Local Storage
```

## Firebase Integration

- **FirebaseService**: Centralized Firebase initialization
- **Firestore**: Primary database for remote data
- **Firebase Auth**: Authentication
- **Firebase Storage**: File uploads (images, etc.)
- **Firebase Messaging**: Push notifications
- **Firebase Analytics**: Analytics tracking

## State Management

- **Provider**: For dependency injection and state management
- **ChangeNotifier**: Base class for controllers
- **Streams**: For real-time data updates from Firestore

## Best Practices

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Dependency Injection**: Use DI container for managing dependencies
3. **Error Handling**: All layers handle errors appropriately
4. **Type Safety**: Use strong typing throughout
5. **Documentation**: Document all public APIs
6. **Testing**: Each layer should be testable in isolation

## Next Steps

1. Complete remaining modules (Home, Orders, Cart, Profile)
2. Add error handling and logging
3. Implement caching strategies
4. Add unit tests for each layer
5. Add integration tests for critical flows
