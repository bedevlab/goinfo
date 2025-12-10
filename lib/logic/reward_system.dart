

class RewardSystem {

  bool canUserPost(int currentBalance, int cost) {
    if (currentBalance >= cost) {
      return true; // Allowed
    } else {
      return false; // Not Allowed
    }
  }


  int calculateRemainingBalance(int currentBalance, int cost) {
    return currentBalance - cost;
  }
}