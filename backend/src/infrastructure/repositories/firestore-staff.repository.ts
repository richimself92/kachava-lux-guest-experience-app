import type { CollectionReference, Firestore } from 'firebase-admin/firestore';
import { StaffMember } from '../../domain/models/domain.models';
import { StaffRepositoryPort } from '../../domain/ports/repository.ports';
import { CONFIG_SCAN_LIMIT } from './firestore-entity.repository';

export const STAFF_COLLECTION = 'staff_members';

/** Staff roster in `staff_members/{staffId}`. Empty until staff are created; never seeded. */
export class FirestoreStaffRepository implements StaffRepositoryPort {
  constructor(private readonly db: Firestore) {}

  async listStaff(department?: string): Promise<StaffMember[]> {
    let query = this.staff().where('isActive', '==', true);
    if (department) query = query.where('department', '==', department.trim().toUpperCase());
    const snapshot = await query.limit(CONFIG_SCAN_LIMIT).get();
    return snapshot.docs.map((doc) => doc.data() as StaffMember);
  }

  async findByStaffId(staffId: string): Promise<StaffMember | null> {
    const snapshot = await this.staff().doc(staffId).get();
    const staff = snapshot.exists ? (snapshot.data() as StaffMember) : null;
    return staff?.isActive ? staff : null;
  }

  findByEmail(email: string): Promise<StaffMember | null> {
    return this.findActiveBy('email', email.trim().toLowerCase());
  }

  findByFirebaseUid(firebaseUid: string): Promise<StaffMember | null> {
    return this.findActiveBy('firebaseUid', firebaseUid);
  }

  private async findActiveBy(field: string, value: string): Promise<StaffMember | null> {
    const snapshot = await this.staff()
      .where(field, '==', value)
      .where('isActive', '==', true)
      .limit(1)
      .get();
    return snapshot.empty ? null : (snapshot.docs[0].data() as StaffMember);
  }

  private staff(): CollectionReference {
    return this.db.collection(STAFF_COLLECTION);
  }
}
