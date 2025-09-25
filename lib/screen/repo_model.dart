class RepoData {
  final String id;
  final String etype;
  final String pNo;
  final String dpd;
  final String bcc;
  final String lpp;
  final String name;
  final String regNum;
  final String engNum;
  final String chasisNo;
  final String stCode;
  final String state;
  final String emiOs;
  final String due;
  final String asset;
  final String make;
  final String close;

  RepoData({
    required this.id,
    required this.etype,
    required this.pNo,
    required this.dpd,
    required this.bcc,
    required this.lpp,
    required this.name,
    required this.regNum,
    required this.engNum,
    required this.chasisNo,
    required this.stCode,
    required this.state,
    required this.emiOs,
    required this.due,
    required this.asset,
    required this.make,
    required this.close,
  });

  factory RepoData.fromJson(Map<String, dynamic> json) => RepoData(
    id: json['id'] ?? "",
    etype: json['etype']?.toString() ?? "",
    pNo: json['p_no'] ?? "",
    dpd: json['dpd'] ?? "",
    bcc: json['bcc'] ?? "",
    lpp: json['lpp'] ?? "",
    name: json['name'] ?? "",
    regNum: json['reg_num'] ?? "",
    engNum: json['eng_num'] ?? "",
    chasisNo: json['chasis_no'] ?? "",
    stCode: json['st_code'] ?? "",
    state: json['state'] ?? "",
    emiOs: json['emi_os'] ?? "",
    due: json['due'] ?? "",
    asset: json['asset'] ?? "",
    make: json['make'] ?? "",
    close: json['close'] ?? "",
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'etype': etype,
    'p_no': pNo,
    'dpd': dpd,
    'bcc': bcc,
    'lpp': lpp,
    'name': name,
    'reg_num': regNum,
    'eng_num': engNum,
    'chasis_no': chasisNo,
    'st_code': stCode,
    'state': state,
    'emi_os': emiOs,
    'due': due,
    'asset': asset,
    'make': make,
    'close': close,
  };
}
