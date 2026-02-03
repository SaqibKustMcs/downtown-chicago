# Firebase Firestore Collections Structure

This document outlines the complete Firebase Firestore database structure for the Food Flow App, supporting three user types: **Admin**, **Customer**, and **Rider**.

## User Types

- **Admin**: Creates restaurants, adds products, manages orders and restaurant operations
- **Customer**: Browses restaurants, places orders, tracks deliveries
- **Rider**: Delivers orders from restaurants to customers

---

## Collections

### 1. `users` Collection

**Path**: `/users/{userId}`

**Description**: Stores user account information for all user types.

**Fields**:
```typescript
{
  email: string (required)
  name: string?
  phoneNumber: string?
  photoUrl: string?
  userType: "admin" | "customer" | "rider" (required)
  emailVerified: boolean (default: false)
  createdAt: Timestamp
  updatedAt: Timestamp
  
  // Rider-specific fields
  isAvailable: boolean?
  vehicleType: string? (e.g., "bike", "car", "motorcycle")
  vehicleNumber: string?
  
  // Admin-specific fields
  restaurantId: string? (reference to restaurant managed by admin)
}
```

**Indexes**:
- `userType` (for filtering by user type)
- `isAvailable` (for finding available riders)
- `restaurantId` (for finding admin's restaurant)

---

### 2. `restaurants` Collection

**Path**: `/restaurants/{restaurantId}`

**Description**: Stores restaurant information. Created and managed by admins.

**Fields**:
```typescript
{
  name: string (required)
  cuisines: string (required) // e.g., "Burger - Chicken - Rice - Wings"
  imageUrl: string (required) // Main restaurant image
  bannerImages: string[]? // Multiple images for carousel/slider
  description: string? // Restaurant description
  address: string? // Restaurant address
  location: {
    latitude: number
    longitude: number
  }? // Restaurant location coordinates
  rating: number (default: 0.0) // Average rating from reviews
  totalRatings: number (default: 0) // Total number of ratings
  deliveryCost: string (required) // e.g., "Free", "$2.99"
  deliveryTime: string (required) // e.g., "20 min", "30-45 min"
  isOpen: boolean (default: true) // Whether restaurant is currently open
  isActive: boolean (default: true) // Admin can deactivate restaurant
  adminId: string (required) // Reference to users/{adminId}
  categoryNames: string[]? // List of category names this restaurant serves (e.g., ["Burger", "Pizza"])
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Indexes**:
- `adminId` (for finding restaurants by admin)
- `isOpen` (for filtering open restaurants)
- `isActive` (for filtering active restaurants)
- `rating` (for sorting by rating)

---

### 3. `products` Collection

**Path**: `/products/{productId}`

**Description**: Stores product/food item information for all restaurants. Created by admins. Each product has a `restaurantId` field to link it to its restaurant.

**Fields**:
```typescript
{
  name: string (required)
  restaurantId: string (required) // Reference to restaurants/{restaurantId}
  restaurantName: string (required) // Denormalized restaurant name for quick access
  description: string?
  imageUrl: string (required) // Main product image
  imageUrls: string[]? // Multiple images for image slider/carousel
  basePrice: number (required) // Base price of the product
  categoryId: string? // Reference to categories/{categoryId}
  categoryName: string? // Denormalized category name for quick access
  isAvailable: boolean (default: true) // Whether product is currently available
  isActive: boolean (default: true) // Admin can deactivate product
  
  // Variations (e.g., Small, Medium, Large)
  variations: {
    name: string (required) // e.g., "Small", "Medium", "Large"
    price: number (required) // Price for this variation
  }[]
  
  // Flavors (e.g., Mild, Spicy, Extra Spicy)
  flavors: {
    name: string (required) // e.g., "Mild", "Spicy", "Extra Spicy"
    price: number (required) // Additional price for this flavor (can be 0)
  }[]
  
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Indexes**:
- `restaurantId` (for finding products by restaurant)
- `categoryName` (for finding products by category)
- `isActive` (for filtering active products)
- `isAvailable` (for filtering available products)
- Composite: `restaurantId + isActive + isAvailable` (for restaurant product listings)
- Composite: `categoryName + isActive + isAvailable` (for category product listings)

---

### 4. `categories` Collection

**Path**: `/categories/{categoryId}`

**Description**: Stores food categories (e.g., Burger, Pizza, Sushi).

**Fields**:
```typescript
{
  name: string (required)
  imageUrl: string (required) // SVG or image URL
  order: number? // For sorting/ordering categories
  isActive: boolean (default: true)
  createdAt: Timestamp
}
```

**Indexes**:
- `isActive` (for filtering active categories)
- `order` (for sorting)

---

### 5. `orders` Collection

**Path**: `/orders/{orderId}`

**Description**: Stores customer orders.

**Fields**:
```typescript
{
  customerId: string (required) // Reference to users/{customerId}
  restaurantId: string (required) // Reference to restaurants/{restaurantId}
  restaurantName: string (required) // Denormalized for quick access
  restaurantImageUrl: string? // Denormalized
  
  // Order items (subcollection)
  // See orderItems subcollection below
  
  // Delivery information
  deliveryAddress: {
    street: string
    city: string
    state: string
    zipCode: string
    latitude: number?
    longitude: number?
    instructions: string?
  }
  
  // Payment information
  paymentMethod: "cash" | "card" | "paypal" | "visa" | "mastercard"
  paymentMethodId: string? // Reference to paymentMethods/{paymentMethodId}
  totalAmount: number (required)
  subtotal: number (required)
  deliveryFee: number (default: 0)
  tax: number (default: 0)
  
  // Order status
  status: "pending" | "confirmed" | "preparing" | "ready" | "out_for_delivery" | "delivered" | "cancelled"
  
  // Rider information (if assigned)
  riderId: string? // Reference to users/{riderId}
  riderName: string? // Denormalized
  riderPhoneNumber: string? // Denormalized
  
  // Timestamps
  orderedAt: Timestamp (required)
  confirmedAt: Timestamp?
  preparingAt: Timestamp?
  readyAt: Timestamp?
  outForDeliveryAt: Timestamp?
  deliveredAt: Timestamp?
  cancelledAt: Timestamp?
  
  // Tracking
  estimatedDeliveryTime: Timestamp? // Estimated delivery time
  actualDeliveryTime: Timestamp? // Actual delivery time
  
  // Customer rating (after delivery)
  rating: number? // 1-5
  review: string?
  
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Subcollections**:
- `orderItems` (see below)
- `tracking` (see below)

**Indexes**:
- `customerId` (for finding customer orders)
- `restaurantId` (for finding restaurant orders)
- `riderId` (for finding rider's assigned orders)
- `status` (for filtering by status)
- `orderedAt` (for sorting by order date)
- `status + orderedAt` (composite for ongoing orders)

---

### 6. `orderItems` Collection (Subcollection)

**Path**: `/orders/{orderId}/orderItems/{orderItemId}`

**Description**: Stores individual items in an order.

**Fields**:
```typescript
{
  productId: string (required) // Reference to restaurants/{restaurantId}/products/{productId}
  productName: string (required) // Denormalized
  productImageUrl: string (required) // Denormalized
  basePrice: number (required)
  quantity: number (required)
  
  // Selected variation and flavor
  selectedVariation: {
    name: string
    price: number
  }?
  selectedFlavor: {
    name: string
    price: number
  }?
  
  // Calculated price
  unitPrice: number (required) // basePrice + variation.price + flavor.price
  totalPrice: number (required) // unitPrice * quantity
}
```

---

### 7. `orderTracking` Collection (Subcollection)

**Path**: `/orders/{orderId}/tracking/{trackingId}`

**Description**: Stores order status updates and location tracking.

**Fields**:
```typescript
{
  status: string (required) // Order status at this point
  message: string? // Status message
  location: {
    latitude: number
    longitude: number
  }? // Rider's location (if out for delivery)
  timestamp: Timestamp (required)
  updatedBy: string? // userId who updated (rider, admin, or system)
}
```

---

### 8. `addresses` Collection (Subcollection)

**Path**: `/users/{userId}/addresses/{addressId}`

**Description**: Stores customer delivery addresses.

**Fields**:
```typescript
{
  label: string (required) // e.g., "Home", "Work"
  street: string (required)
  city: string (required)
  state: string (required)
  zipCode: string (required)
  latitude: number?
  longitude: number?
  instructions: string? // Delivery instructions
  isDefault: boolean (default: false)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Indexes**:
- `isDefault` (for finding default address)

---

### 9. `paymentMethods` Collection (Subcollection)

**Path**: `/users/{userId}/paymentMethods/{paymentMethodId}`

**Description**: Stores customer saved payment methods.

**Fields**:
```typescript
{
  type: "card" | "paypal" | "visa" | "mastercard" (required)
  cardNumber: string? // Last 4 digits only for security
  cardHolderName: string?
  expiryMonth: number?
  expiryYear: number?
  isDefault: boolean (default: false)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Indexes**:
- `isDefault` (for finding default payment method)

---

### 10. `favorites` Collection (Subcollection)

**Path**: `/users/{userId}/favorites/{favoriteId}`

**Description**: Stores customer's favorite products.

**Fields**:
```typescript
{
  productId: string (required) // Reference to restaurants/{restaurantId}/products/{productId}
  restaurantId: string (required) // Reference to restaurants/{restaurantId}
  productName: string (required) // Denormalized
  productImageUrl: string (required) // Denormalized
  restaurantName: string (required) // Denormalized
  createdAt: Timestamp
}
```

**Indexes**:
- `productId` (for checking if product is favorited)
- `restaurantId` (for filtering by restaurant)

---

### 11. `notifications` Collection (Subcollection)

**Path**: `/users/{userId}/notifications/{notificationId}`

**Description**: Stores user notifications.

**Fields**:
```typescript
{
  title: string (required)
  message: string (required)
  type: "order" | "promotion" | "general" | "system" (required)
  orderId: string? // Reference to orders/{orderId} (if type is "order")
  isRead: boolean (default: false)
  timestamp: Timestamp (required)
  createdAt: Timestamp
}
```

**Indexes**:
- `isRead` (for filtering unread notifications)
- `timestamp` (for sorting by date)
- `type` (for filtering by type)

---

### 12. `chats` Collection

**Path**: `/chats/{chatId}`

**Description**: Stores chat conversations (e.g., customer-rider, customer-restaurant).

**Fields**:
```typescript
{
  participants: string[] (required) // Array of userIds
  orderId: string? // Reference to orders/{orderId} (if chat is related to an order)
  lastMessage: string?
  lastMessageTimestamp: Timestamp?
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Subcollections**:
- `messages` (see below)

**Indexes**:
- `participants` (array-contains for finding user's chats)
- `orderId` (for finding chat by order)
- `lastMessageTimestamp` (for sorting by recent activity)

---

### 13. `messages` Collection (Subcollection)

**Path**: `/chats/{chatId}/messages/{messageId}`

**Description**: Stores chat messages.

**Fields**:
```typescript
{
  senderId: string (required) // Reference to users/{senderId}
  text: string (required)
  timestamp: Timestamp (required)
  isRead: boolean (default: false)
  createdAt: Timestamp
}
```

**Indexes**:
- `timestamp` (for sorting messages chronologically)

---

### 14. `cart` Collection (Subcollection)

**Path**: `/users/{userId}/cart/{cartItemId}`

**Description**: Stores customer's shopping cart items.

**Fields**:
```typescript
{
  productId: string (required) // Reference to restaurants/{restaurantId}/products/{productId}
  restaurantId: string (required) // Reference to restaurants/{restaurantId}
  productName: string (required) // Denormalized
  productImageUrl: string (required) // Denormalized
  basePrice: number (required)
  quantity: number (required)
  
  // Selected variation and flavor
  selectedVariation: {
    name: string
    price: number
  }?
  selectedFlavor: {
    name: string
    price: number
  }?
  
  // Calculated price
  unitPrice: number (required) // basePrice + variation.price + flavor.price
  totalPrice: number (required) // unitPrice * quantity
  
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**Indexes**:
- `restaurantId` (for filtering by restaurant)

---

## Security Rules (Firestore Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    
    function isRider() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'rider';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }
    
    // Restaurants collection
    match /restaurants/{restaurantId} {
      allow read: if isAuthenticated();
      allow create: if isAdmin();
      allow update: if isAdmin() && 
                       resource.data.adminId == request.auth.uid;
      allow delete: if isAdmin() && 
                       resource.data.adminId == request.auth.uid;
      
      // Products subcollection
      match /products/{productId} {
        allow read: if isAuthenticated();
        allow create: if isAdmin();
        allow update: if isAdmin();
        allow delete: if isAdmin();
      }
    }
    
    // Categories collection
    match /categories/{categoryId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin();
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isAuthenticated() && (
        resource.data.customerId == request.auth.uid ||
        resource.data.restaurantId in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.restaurantId ||
        resource.data.riderId == request.auth.uid ||
        isAdmin()
      );
      allow create: if isAuthenticated() && 
                       request.resource.data.customerId == request.auth.uid;
      allow update: if isAuthenticated() && (
        resource.data.customerId == request.auth.uid ||
        resource.data.restaurantId in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.restaurantId ||
        resource.data.riderId == request.auth.uid ||
        isAdmin()
      );
      
      // Order items subcollection
      match /orderItems/{orderItemId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && 
                         request.resource.data.orderId == orderId;
      }
      
      // Tracking subcollection
      match /tracking/{trackingId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && (
          isRider() || isAdmin()
        );
      }
    }
    
    // User subcollections (addresses, paymentMethods, favorites, notifications, cart)
    match /users/{userId}/addresses/{addressId} {
      allow read, write: if isOwner(userId);
    }
    
    match /users/{userId}/paymentMethods/{paymentMethodId} {
      allow read, write: if isOwner(userId);
    }
    
    match /users/{userId}/favorites/{favoriteId} {
      allow read, write: if isOwner(userId);
    }
    
    match /users/{userId}/notifications/{notificationId} {
      allow read, write: if isOwner(userId);
    }
    
    match /users/{userId}/cart/{cartItemId} {
      allow read, write: if isOwner(userId);
    }
    
    // Chats collection
    match /chats/{chatId} {
      allow read: if isAuthenticated() && 
                     request.auth.uid in resource.data.participants;
      allow create: if isAuthenticated() && 
                       request.auth.uid in request.resource.data.participants;
      allow update: if isAuthenticated() && 
                       request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isAuthenticated() && 
                       request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if isAuthenticated() && 
                         request.resource.data.senderId == request.auth.uid &&
                         request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      }
    }
  }
}
```

---

## Data Flow Examples

### Customer Places Order
1. Customer adds items to cart (`/users/{customerId}/cart`)
2. Customer selects delivery address and payment method
3. Create order document in `/orders/{orderId}`
4. Create order items in `/orders/{orderId}/orderItems`
5. Clear customer's cart
6. Create notification for restaurant admin
7. Update order status to "pending"

### Admin Confirms Order
1. Admin views pending orders for their restaurant
2. Update order status to "confirmed"
3. Create tracking entry in `/orders/{orderId}/tracking`
4. Create notification for customer

### Rider Accepts Delivery
1. Rider views available orders (status: "ready")
2. Rider updates order with their `riderId`
3. Update order status to "out_for_delivery"
4. Create tracking entry with rider location
5. Create notification for customer

### Order Delivered
1. Rider updates order status to "delivered"
2. Create tracking entry
3. Create notification for customer to rate
4. Customer can add rating and review

---

## Indexes Required

Create these composite indexes in Firebase Console:

1. **orders** collection:
   - `status` (Ascending) + `orderedAt` (Descending)
   - `customerId` (Ascending) + `orderedAt` (Descending)
   - `restaurantId` (Ascending) + `status` (Ascending) + `orderedAt` (Descending)
   - `riderId` (Ascending) + `status` (Ascending) + `orderedAt` (Descending)

2. **restaurants** collection:
   - `isOpen` (Ascending) + `rating` (Descending)
   - `isActive` (Ascending) + `rating` (Descending)

3. **chats** collection:
   - `participants` (Array) + `lastMessageTimestamp` (Descending)

---

## Notes

- All timestamps use Firestore `Timestamp` type
- Denormalized fields (like `restaurantName` in orders) improve query performance
- Subcollections are used for related data that doesn't need to be queried independently
- Indexes are crucial for efficient queries, especially composite indexes
- Security rules ensure users can only access their own data or data they're authorized to see
