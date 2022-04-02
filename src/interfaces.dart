enum ApiStatus { ok, error }

class SegmentResource {
  final String segmentId;
  final Map<String, dynamic>? dataBag;
  final int lastModifiedTs;
  final int creationTs;
  final int? expirationTs;

  DateTime get lastModifiedDate {
    return DateTime.fromMillisecondsSinceEpoch(lastModifiedTs);
  }

  DateTime get creationDate {
    return DateTime.fromMillisecondsSinceEpoch(creationTs);
  }

  DateTime? get expirationDate {
    if (expirationTs == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(expirationTs as int);
  }

  SegmentResource(this.segmentId, this.dataBag, this.lastModifiedTs,
      this.creationTs, this.expirationTs);

  SegmentResource.fromJSON(Map<String, dynamic> json)
      : segmentId = json['segment_id'],
        dataBag = json['data_bag'],
        lastModifiedTs = json['last_modified_ts'],
        creationTs = json['creation_ts'],
        expirationTs = json['expiration_ts'];
}

class SegmentListResource {
  final ApiStatus status;
  final List<SegmentResource> data;
  final int count;

  SegmentListResource(
      {required this.status, required this.data, required this.count});

  SegmentListResource.fromJSON(Map<String, dynamic> json)
      : status = ApiStatus.values[ApiStatus.values.indexOf(json['status'])],
        data = (json['data'] as List<Map<String, dynamic>>)
            .map((e) => SegmentResource.fromJSON(e))
            .toList(),
        count = json['count'];
}

enum UserIdentifierType { USER_EMAIL, USER_ACCOUNT }

class UserIdentifier {
  final UserIdentifierType type;

  UserIdentifier(this.type);

  Map<String, dynamic> get formatted {
    return {};
  }
}

class UserEmailIdentifier extends UserIdentifier {
  final String hash;
  final String? email;

  UserEmailIdentifier(this.hash, {this.email})
      : super(UserIdentifierType.USER_EMAIL);

  @override
  Map<String, Map<String, String>> get formatted {
    Map<String, Map<String, String>> map = {
      '\$email_hash': {
        '\$hash': hash,
      }
    };
    if (email != null) {
      map['\$email_hash']!['\$email'] = email as String;
    }
    return map;
  }
}

class UserAccountIdentifier extends UserIdentifier {
  final String userAccountId;
  final String compartmentId;

  UserAccountIdentifier(this.userAccountId, this.compartmentId)
      : super(UserIdentifierType.USER_ACCOUNT);

  @override
  Map<String, String> get formatted {
    return {
      '\$user_account_id': userAccountId,
      '\$compartmentId': compartmentId
    };
  }
}

class UserActivityResource {
  final ApiStatus status;
  final bool data;

  UserActivityResource(this.status, this.data);

  UserActivityResource.fromJSON(Map<String, dynamic> json)
      : status = ApiStatus.values[ApiStatus.values.indexOf(json['status'])],
        data = json['data'];
}
