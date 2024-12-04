-- Ispis svih jela koja imaju cijenu manju od 15 eura
SELECT d.Name, d.Price
FROM Dish d
WHERE d.Price < 15;

-- Ispis svih narudžbi iz 2023. godine koje imaju ukupnu vrijednost veću od 50 eura.
SELECT o.OrderId, o.Date, o.TotalPrice
FROM Orders o
WHERE EXTRACT(YEAR FROM o.Date) = 2023
AND o.TotalPrice > 50;

-- Ispis svih dostavljača s više od 100 uspješno izvršenih dostava do danas.
SELECT s.StaffId, s.Name, s.Surname, COUNT(o.OrderId) AS Deliveries
FROM Staff s
JOIN Orders o ON s.StaffId = o.StaffId
WHERE s.Role = 'Deliverer'
GROUP BY s.StaffId, s.Name, s.Surname
HAVING COUNT(o.OrderId) > 100;

-- Ispis svih kuhara koji rade u restoranima u Zagrebu.
SELECT s.StaffId, s.Name, s.Surname, r.Name AS RestaurantName
FROM Staff s
JOIN Restaurant r ON s.RestaurantId = r.RestaurantId
JOIN City c ON r.CityId = c.CityId
WHERE s.Role = 'Chef'
  AND c.Name = 'Zagreb';

-- Ispis broja narudžbi za svaki restoran u Splitu tijekom 2023. godine.
SELECT r.RestaurantId, r.Name AS RestaurantName, COUNT(o.OrderId) AS TotalOrders
FROM Restaurant r
JOIN City c ON r.CityId = c.CityId
JOIN Staff s ON r.RestaurantId = s.RestaurantId
JOIN Orders o ON s.StaffId = o.StaffId
WHERE c.Name = 'Split'
  AND EXTRACT(YEAR FROM o.Date) = 2023
GROUP BY r.RestaurantId, r.Name;

-- Ispis svih jela u kategoriji "Deserti" koja su naručena više od 10 puta u prosincu 2023.
SELECT d.Name, SUM(omi.Amount) AS TotalOrdered
FROM OrderMenuItems omi
JOIN MenuItems mi ON omi.MenuItemId = mi.MenuItemId
JOIN Dish d ON mi.DishId = d.DishId
JOIN Orders o ON omi.OrderId = o.OrderId
WHERE d.Category = 'Dessert'
  AND EXTRACT(YEAR FROM o.Date) = 2023
  AND EXTRACT(MONTH FROM o.Date) = 12
GROUP BY d.DishId, d.Name
HAVING SUM(omi.Amount) > 10;

-- Ispis broja narudžbi korisnika s prezimenom koje počinje na "M".
SELECT u.UserId, u.Surname, COUNT(o.OrderId) AS TotalOrders
FROM Users u
JOIN Orders o ON u.UserId = o.UserId
WHERE u.Surname LIKE 'M%'
GROUP BY u.UserId, u.Surname;

-- Ispis prosječne ocjene za restorane u Rijeci.
SELECT r.Name AS RestaurantName, AVG(rw.Rating) AS AverageRating
FROM Restaurant r
JOIN City c ON r.CityId = c.CityId
JOIN MenuItems mi ON r.RestaurantId = mi.RestaurantId
JOIN OrderMenuItems omi ON mi.MenuItemId = omi.MenuItemId
JOIN Review rw ON omi.OrderMenuItemId = rw.OrderMenuItemId
WHERE c.Name = 'Rijeka'
GROUP BY r.RestaurantId, r.Name;

-- Ispis svih restorana koji imaju kapacitet veći od 30 stolova i nude dostavu.
SELECT RestaurantId, Name, Capacity
FROM Restaurant
WHERE Capacity > 30
  AND OffersDelivery = TRUE;

-- Uklonite iz jelovnika jela koja nisu naručena u posljednje 2 godine.
UPDATE MenuItems
SET DeletedAt = CURRENT_TIMESTAMP
WHERE MenuItemId IN (
    SELECT mi.MenuItemId
    FROM MenuItems mi
    LEFT JOIN OrderMenuItems omi ON mi.MenuItemId = omi.MenuItemId
    LEFT JOIN Orders o ON omi.OrderId = o.OrderId
    WHERE o.Date < CURRENT_DATE - INTERVAL '2 years' OR o.Date IS NULL
);

-- Izbrišite loyalty kartice svih korisnika koji nisu naručili nijedno jelo u posljednjih godinu dana.
UPDATE Users
SET LoyaltyCard = FALSE
WHERE UserId IN (
    SELECT u.UserId
    FROM Users u
    LEFT JOIN Orders o ON u.UserId = o.UserId
    WHERE o.Date < NOW() - INTERVAL '1 year'
);
