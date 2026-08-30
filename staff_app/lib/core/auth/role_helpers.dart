const kExportRoles = {
  'manager',
  'reception_manager',
  'maintenance_manager',
  'housekeeping_manager',
  'security_manager',
  'ceo',
  'hotel_admin',
  'super_admin',
};

bool canExportData(String? role) => kExportRoles.contains(role);
