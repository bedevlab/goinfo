// lib/logic/reward_system.dart

class RewardSystem {
  // Logic: Check if user can afford to post
  bool canUserPost(int currentBalance, int cost) {
    if (currentBalance >= cost) {
      return true; // Allowed
    } else {
      return false; // Not Allowed
    }
  }

  // Logic: Calculate new balance after posting
  int calculateRemainingBalance(int currentBalance, int cost) {
    return currentBalance - cost;
  }
}