-- ============================================================
-- Migration 007: Notification Triggers
-- Run AFTER 006_notifications.sql
-- ============================================================

-- Function to handle equipment loan status changes
CREATE OR REPLACE FUNCTION handle_loan_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO notifications (
      user_id,
      title,
      body,
      type,
      reference_type,
      reference_id
    ) VALUES (
      NEW.borrower_id,
      'Loan Status Updated',
      'Your equipment loan request status is now: ' || REPLACE(NEW.status, '_', ' '),
      'loan',
      'equipment_loan',
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for equipment loans
DROP TRIGGER IF EXISTS trg_loan_status_notification ON equipment_loans;
CREATE TRIGGER trg_loan_status_notification
  AFTER UPDATE OF status ON equipment_loans
  FOR EACH ROW
  EXECUTE FUNCTION handle_loan_status_change();


-- Function to handle maintenance request status changes
CREATE OR REPLACE FUNCTION handle_maintenance_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO notifications (
      user_id,
      title,
      body,
      type,
      reference_type,
      reference_id
    ) VALUES (
      NEW.requester_id,
      'Maintenance Request Updated',
      'Your maintenance request status is now: ' || REPLACE(NEW.status, '_', ' '),
      'maintenance',
      'maintenance_request',
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for maintenance requests
DROP TRIGGER IF EXISTS trg_maintenance_status_notification ON maintenance_requests;
CREATE TRIGGER trg_maintenance_status_notification
  AFTER UPDATE OF status ON maintenance_requests
  FOR EACH ROW
  EXECUTE FUNCTION handle_maintenance_status_change();
