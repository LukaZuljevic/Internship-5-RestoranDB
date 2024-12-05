CREATE TABLE City(
    CityId SERIAL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL UNIQUE,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL
);

CREATE TABLE Restaurant(
    RestaurantId SERIAL PRIMARY KEY,
    CityId INT References City(CityId),
    Name VARCHAR(50) NOT NULL,
    Capacity INT CHECK(Capacity > 0),
    StartTime TIME NOT NULL,
    EndTime TIME CHECK(EndTime >= StartTime),
    OffersDelivery BOOLEAN NOT NULL,
    CONSTRAINT UniqueRestaurantNameCity UNIQUE (Name, CityId) 
);

CREATE TABLE Users(
    UserId SERIAL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    Surname VARCHAR(30) NOT NULL,
    Birthdate TIMESTAMP CHECK(Birthdate < CURRENT_TIMESTAMP),
    LoyaltyCard BOOLEAN DEFAULT FALSE
);

CREATE TABLE Dish(
    DishId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Category VARCHAR(30) CHECK (Category IN ('Appetizer', 'Main course', 'Dessert', 'Drink', 'Side dish')),
    Price FLOAT CHECK(Price > 0),
    Calories INT CHECK(Calories > 0),
    CONSTRAINT UniqueDish UNIQUE (Name, Category, Calories)
);

CREATE TABLE Staff(
    StaffId SERIAL PRIMARY KEY,
    RestaurantId INT References Restaurant(RestaurantId),
    Name VARCHAR(30) NOT NULL,
    Surname VARCHAR(30) NOT NULL,
    Age INT CHECK(Age > 0),
    Role VARCHAR(30) CHECK (Role IN ('Chef', 'Waiter', 'Deliverer')),
    HasDriverLicense BOOLEAN NOT NULL
);

CREATE TABLE Orders(
    OrderId SERIAL PRIMARY KEY,
    UserId INT References Users(UserId),
    StaffId INT References Staff(StaffId),
    IsForDelivery BOOLEAN NOT NULL,
    DeliveryNote VARCHAR(150),
    Address VARCHAR(50),
    Date TIMESTAMP CHECK(Date < CURRENT_TIMESTAMP),
    TotalPrice FLOAT CHECK(TotalPrice >= 0),
    CONSTRAINT UniqueUserPerOrder UNIQUE (OrderId, UserId) 
);

CREATE TABLE MenuItems(
    MenuItemId SERIAL PRIMARY KEY,
    RestaurantId INT References Restaurant(RestaurantId),
    DishId INT References Dish(DishId),
    DeletedAt TIMESTAMP,
    IsAvailable BOOLEAN DEFAULT TRUE,
    CONSTRAINT UniqueDishInRestaurant UNIQUE (RestaurantId, DishId)
);

CREATE TABLE OrderMenuItems (
    OrderMenuItemId SERIAL PRIMARY KEY,
    OrderId INT References Orders(OrderId),
    MenuItemId INT References MenuItems(MenuItemId),
    Amount INT CHECK (Amount > 0)
);

CREATE TABLE Review(
    ReviewId SERIAL PRIMARY KEY,
    OrderMenuItemId INT References OrderMenuItems(OrderMenuItemId),
    Comment VARCHAR(100),
    Rating INT CHECK(Rating BETWEEN 1 AND 5)
);


ALTER TABLE Orders 
ADD CONSTRAINT CheckDelivery
CHECK (
    (IsForDelivery = TRUE AND Address IS NOT NULL) 
    OR (IsForDelivery = FALSE AND Address IS NULL)
    OR (IsForDelivery = FALSE AND DeliveryNote IS NULL)
);

    
ALTER TABLE Staff
ADD CONSTRAINT CheckDelivererAgeAndLicense
CHECK (
    Role != 'Deliverer' 
    OR (HasDriverLicense = TRUE AND Age >= 18)
);


ALTER TABLE Staff 
ADD CONSTRAINT CheckChefAge 
CHECK (Role != 'Chef' OR Age >= 18);

ALTER TABLE Staff
ADD CONSTRAINT UniqueStaffRestaurant
UNIQUE (StaffId, RestaurantId);

ALTER TABLE Orders
ADD CONSTRAINT CheckOrderDate
CHECK (Date <= CURRENT_TIMESTAMP);

ALTER TABLE MenuItems
ADD CONSTRAINT CheckIfMenuItemValid CHECK(IsAvailable = TRUE);

--nakon unosa podataka
UPDATE Users
SET LoyaltyCard = TRUE
WHERE UserId IN (
    SELECT o.UserId
    FROM Orders o
    GROUP BY o.UserId
    HAVING COUNT(o.OrderId) > 4 AND SUM(o.TotalPrice) > 1000
);


UPDATE Orders
SET TotalPrice = subquery.TotalPrice
FROM (
    SELECT 
        o.OrderId,
        SUM(d.Price * omi.Amount) AS TotalPrice
    FROM Orders o
    JOIN OrderMenuItems omi ON o.OrderId = omi.OrderId
    JOIN MenuItems mi ON omi.MenuItemId = mi.MenuItemId
    JOIN Dish d ON mi.DishId = d.DishId
    GROUP BY o.OrderId
) AS subquery
WHERE Orders.OrderId = subquery.OrderId;

