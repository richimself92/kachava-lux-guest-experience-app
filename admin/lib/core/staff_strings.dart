import '../domain/staff_member.dart';
import 'service_catalog_labels.dart';

/// EN/ES copy of Settings › Staff (1-3 word labels).
class StaffStrings {
  const StaffStrings(this.isEs);

  final bool isEs;

  String t(String en, String es) => isEs ? es : en;

  String get general => t('General', 'General');
  String get staff => t('Staff', 'Personal');
  String get staffInfo => t('Team members offered in owner pickers.',
      'Equipo disponible en los selectores de responsable.');
  String get newStaff => t('New staff', 'Nuevo miembro');
  String get noStaff => t('No staff yet', 'Aún no hay personal');
  String get notConnected => t('Staff not connected', 'Personal sin conexión');

  String get name => t('Name', 'Nombre');
  String get role => t('Role', 'Rol');
  String get department => t('Department', 'Departamento');
  String get email => t('Email', 'Email');
  String get phone => t('Phone', 'Teléfono');
  String get jobTitle => t('Job title', 'Puesto');
  String get active => t('Active', 'Activo');
  String get inactive => t('Inactive', 'Inactivo');
  String get more => t('More', 'Más');
  String get yes => t('Yes', 'Sí');
  String get no => t('No', 'No');
  String get actions => t('Actions', 'Acciones');
  String get cancel => t('Cancel', 'Cancelar');
  String get deactivate => t('Deactivate', 'Desactivar');
  String get activate => t('Activate', 'Activar');
  String deactivateQ(String name) =>
      t('Deactivate $name?', '¿Desactivar a $name?');
  String activateQ(String name) => t('Activate $name?', '¿Activar a $name?');
  String get saved => t('Staff saved', 'Personal guardado');
  String get deactivated => t('Staff deactivated', 'Personal desactivado');
  String get activated => t('Staff activated', 'Personal activado');
  String get saveFailed => t("Couldn't save", 'No se pudo guardar');
  String get emailTaken => t('Email already used', 'Email ya registrado');
  String get invalidEmail => t('Enter a valid email', 'Email no válido');

  String roleLabel(StaffRole r) => switch (r) {
        StaffRole.hostAdmin => t('Host admin', 'Administrador'),
        StaffRole.conciergeStaff => 'Resort Host',
        StaffRole.departmentCoordinator => t('Coordinator', 'Coordinador'),
      };

  String departmentLabel(StaffDepartment d) =>
      ServiceCatalogLabels(isEs).department(d.apiValue);
}
