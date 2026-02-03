import 'package:flutter/material.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/models/restaurant_model.dart';
import 'package:food_flow_app/modules/widgets/restaurant_card.dart';
import 'package:food_flow_app/modules/widgets/top_navigation_bar.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';

class AllRestaurantsScreen extends StatelessWidget {
  const AllRestaurantsScreen({super.key});

  static const List<Restaurant> _allRestaurants = [
    Restaurant(
      name: 'Rose Garden Restaurant',
      cuisines: 'Burger - Chicken - Rice - Wings',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.7,
      deliveryCost: 'Free',
      deliveryTime: '20 min',
    ),
    Restaurant(
      name: 'Burger King',
      cuisines: 'Burger - Fries - Chicken',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.5,
      deliveryCost: 'Free',
      deliveryTime: '25 min',
    ),
    Restaurant(
      name: 'Pizza Hut',
      cuisines: 'Pizza - Pasta - Wings',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.6,
      deliveryCost: '\$2.99',
      deliveryTime: '30 min',
    ),
    Restaurant(
      name: 'KFC',
      cuisines: 'Chicken - Wings - Fries',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.4,
      deliveryCost: 'Free',
      deliveryTime: '22 min',
    ),
    Restaurant(
      name: 'McDonald\'s',
      cuisines: 'Burger - Fries - Nuggets',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.3,
      deliveryCost: 'Free',
      deliveryTime: '18 min',
    ),
    Restaurant(
      name: 'Subway',
      cuisines: 'Sandwich - Salad - Wrap',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.2,
      deliveryCost: 'Free',
      deliveryTime: '15 min',
    ),
    Restaurant(
      name: 'Domino\'s Pizza',
      cuisines: 'Pizza - Pasta - Bread',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.5,
      deliveryCost: '\$1.99',
      deliveryTime: '25 min',
    ),
    Restaurant(
      name: 'Taco Bell',
      cuisines: 'Tacos - Burrito - Nachos',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.1,
      deliveryCost: 'Free',
      deliveryTime: '20 min',
    ),
    Restaurant(
      name: 'Starbucks',
      cuisines: 'Coffee - Pastry - Sandwiches',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.6,
      deliveryCost: '\$3.99',
      deliveryTime: '18 min',
    ),
    Restaurant(
      name: 'Wendy\'s',
      cuisines: 'Burger - Chicken - Fries',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.4,
      deliveryCost: 'Free',
      deliveryTime: '22 min',
    ),
    Restaurant(
      name: 'Dunkin\' Donuts',
      cuisines: 'Donuts - Coffee - Breakfast',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.3,
      deliveryCost: '\$2.99',
      deliveryTime: '20 min',
    ),
    Restaurant(
      name: 'Chipotle',
      cuisines: 'Burrito - Bowl - Tacos',
      imageUrl: 'https://www.recipetineats.com/tachyon/2022/08/Stack-of-cheeseburgers.jpg?resize=900%2C1125&zoom=1',
      rating: 4.5,
      deliveryCost: 'Free',
      deliveryTime: '25 min',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(title: 'All Restaurants'),

            // Restaurants List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                itemCount: _allRestaurants.length,
                itemBuilder: (context, index) {
                  return AnimatedListItem(
                    index: index,
                    child: RestaurantCardHorizontal(restaurant: _allRestaurants[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
