const Map<String, String> kUserDisplayNames = {
  'userA': 'Wei',
  'userB': 'Shuyi',
};

String partnerId(String userId) => userId == 'userA' ? 'userB' : 'userA';

String partnerDisplayName(String userId) =>
    kUserDisplayNames[partnerId(userId)] ?? 'Unknown';

String displayNameFor(String userId) =>
    kUserDisplayNames[userId] ?? userId;
