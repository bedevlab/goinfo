import 'package:flutter_test/flutter_test.dart';
import 'package:goinfo/logic/reward_system.dart'; 

void main() {
  group('Reward System Tests', () {
    final rewardSystem = RewardSystem();

    test('User should be allowed to post if they have enough points', () {
      
      int balance = 50;
      int cost = 5;

     
      bool result = rewardSystem.canUserPost(balance, cost);

      
      expect(result, true);
    });

    test('User should NOT be allowed to post if balance is too low', () {
     
      int balance = 2;
      int cost = 5;

      
      bool result = rewardSystem.canUserPost(balance, cost);


      expect(result, false);
    });

    test('Balance calculation should be correct', () {

      int balance = 50;
      int cost = 5;


      int newBalance = rewardSystem.calculateRemainingBalance(balance, cost);


      expect(newBalance, 45);
    });
  });
}