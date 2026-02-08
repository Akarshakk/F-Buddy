import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';

class SplitWiseProvider extends ChangeNotifier {
  List<Group> _groups = [];
  Group? _currentGroup;
  bool _isLoading = false;
  String? _errorMessage;

  List<Group> get groups => _groups;
  Group? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all groups for current user from MongoDB
  Future<void> fetchGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/groups');
      
      if (response['success'] == true && response['data'] != null) {
        // Backend returns: {success: true, data: {groups: [...]}}
        final groupsList = response['data']['groups'] as List;
        _groups = groupsList.map((json) => Group.fromJson(json)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch groups';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get group by ID from MongoDB
  Future<void> fetchGroupById(String groupId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/groups/$groupId');
      
      if (response['success'] == true && response['data'] != null) {
        // Backend returns: {success: true, data: {group: {...}}}
        _currentGroup = Group.fromJson(response['data']['group']);
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = _currentGroup!;
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch group';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new group and save to MongoDB
  Future<bool> createGroup({
    required String name,
    required String description,
    required List<String> memberEmails,
    required String userId,
    required String userName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/groups',
        body: {
          'name': name,
          'description': description,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // Backend returns: {success: true, data: {group: {...}}}
        final newGroup = Group.fromJson(response['data']['group']);
        _groups.add(newGroup);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create group';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add expense to group and save to MongoDB
  Future<bool> addGroupExpense({
    required String groupId,
    required String description,
    required double amount,
    required String category,
    required String paidBy,
    required String paidByName,
    required List<GroupExpenseSplit> splits,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/groups/$groupId/expenses',
        body: {
          'description': description,
          'amount': amount,
          'category': category,
          'paidBy': paidBy,
          'paidByName': paidByName,
          'splits': splits.map((s) => s.toJson()).toList(),
          'date': date.toIso8601String(),
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // Backend returns: {success: true, data: {group: {...}}}
        final updatedGroup = Group.fromJson(response['data']['group']);
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = updatedGroup;
        }
        _currentGroup = updatedGroup;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add expense';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add member to group in MongoDB
  Future<bool> addMemberToGroup({
    required String groupId,
    required String userId,
    required String name,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/groups/$groupId/members',
        body: {
          'memberEmail': email,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // Backend returns: {success: true, data: {group: {...}}}
        final updatedGroup = Group.fromJson(response['data']['group']);
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = updatedGroup;
        }
        _currentGroup = updatedGroup;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add member';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Join group using invite code via MongoDB
  Future<bool> joinGroupByCode({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/groups/join',
        body: {
          'inviteCode': inviteCode,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // Backend returns: {success: true, data: {group: {...}}}
        final group = Group.fromJson(response['data']['group']);
        _groups.add(group);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to join group';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a group from MongoDB
  Future<bool> deleteGroup(String groupId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('/groups/$groupId');

      if (response['success'] == true) {
        _groups.removeWhere((g) => g.id == groupId);
        if (_currentGroup?.id == groupId) {
          _currentGroup = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete group';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete group expense
  Future<bool> deleteGroupExpense(String groupId, String expenseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('/groups/$groupId/expenses/$expenseId');

      if (response['success'] == true && response['data'] != null) {
        final updatedGroup = Group.fromJson(response['data']['group']);
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = updatedGroup;
        }
        _currentGroup = updatedGroup;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete expense';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Settle up payment between members
  Future<bool> settleUp({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/groups/$groupId/settle',
        body: {
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'amount': amount,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final updatedGroup = Group.fromJson(response['data']['group']);
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = updatedGroup;
        }
        _currentGroup = updatedGroup;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to settle payment';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Transfer group ownership
  Future<bool> transferOwnership(String groupId, String newOwnerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/groups/$groupId/transfer',
        body: {'newOwnerId': newOwnerId},
      );

      if (response['success'] == true && response['data'] != null) {
        final updatedGroup = Group.fromJson(response['data']['group']);
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = updatedGroup;
        }
        _currentGroup = updatedGroup;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to transfer ownership';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Leave a group
  Future<bool> leaveGroup(String groupId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/groups/$groupId/leave', body: {});

      if (response['success'] == true) {
        _groups.removeWhere((g) => g.id == groupId);
        if (_currentGroup?.id == groupId) {
          _currentGroup = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to leave group';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}


