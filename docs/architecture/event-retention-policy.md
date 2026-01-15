# Event Retention Policy

**Version:** 1.0  
**Date:** January 6, 2026  
**Story:** 3.1 - Event-Driven Architecture Foundation

---

## Overview

The events table serves as the immutable audit log for the PARTNERSLLC platform. This document defines the retention policy for events, ensuring compliance, auditability, and system performance.

## Policy Statement

**Primary Recommendation: Keep events forever for audit purposes**

Events are immutable records that provide a complete audit trail of all significant actions in the system. They are critical for:
- Compliance and legal requirements
- Debugging and troubleshooting
- Analytics and reporting
- User support and dispute resolution
- Security auditing

## Retention Strategy

### Current Implementation

**Retention Period:** Indefinite (forever)

All events are retained indefinitely in the `events` table. No automatic deletion or archival is currently implemented.

### Rationale

1. **Audit Requirements**: Business services require complete audit trails for compliance
2. **Low Storage Cost**: JSONB payloads are efficient, and events are relatively small records
3. **Query Performance**: Indexes on `entity_type`, `entity_id`, `event_type`, `actor_id`, and `created_at` ensure fast queries even with large datasets
4. **Legal Compliance**: May be required for regulatory compliance in certain jurisdictions

## Alternative: 2-Year Archival (Future Consideration)

If storage costs become a concern or if specific compliance requirements mandate archival, the following process can be implemented:

### Archival Process

1. **Create Archive Table**
   ```sql
   CREATE TABLE events_archive (
     LIKE events INCLUDING ALL
   );
   ```

2. **Archival Script** (run monthly or quarterly)
   ```sql
   -- Move events older than 2 years to archive
   INSERT INTO events_archive
   SELECT * FROM events
   WHERE created_at < NOW() - INTERVAL '2 years';
   
   -- Delete archived events from main table
   DELETE FROM events
   WHERE created_at < NOW() - INTERVAL '2 years';
   ```

3. **Query Considerations**
   - Update query utilities to check both `events` and `events_archive` tables
   - Or maintain a view that unions both tables
   - Archive table can be stored in cheaper storage (e.g., S3, cold storage)

### When to Implement Archival

Consider implementing archival if:
- Events table exceeds 10 million records
- Storage costs become significant (>$100/month for events)
- Specific compliance requirements mandate archival
- Query performance degrades despite proper indexing

## Indexes for Performance

The following indexes ensure fast queries even with large datasets:

```sql
-- Indexes on events table
CREATE INDEX idx_events_entity ON events(entity_type, entity_id);
CREATE INDEX idx_events_event_type ON events(event_type);
CREATE INDEX idx_events_actor ON events(actor_type, actor_id);
CREATE INDEX idx_events_created_at ON events(created_at DESC);
```

These indexes support:
- Fast queries by dossier (`entity_type = 'dossier'`, `entity_id = dossier_id`)
- Fast queries by user (`actor_id = user_id`)
- Fast queries by event type (`event_type = 'DOCUMENT_UPLOADED'`)
- Fast chronological queries (`ORDER BY created_at DESC`)

## Monitoring

### Key Metrics to Track

1. **Table Size**: Monitor `events` table size monthly
2. **Query Performance**: Track query execution times for event queries
3. **Storage Costs**: Monitor database storage costs
4. **Event Volume**: Track events created per day/week/month

### Alert Thresholds

Set up alerts if:
- Events table exceeds 50GB
- Average query time exceeds 500ms
- Event creation rate exceeds 10,000/day consistently

## Implementation Notes

### Current Constraints

- **Immutability**: Events cannot be updated or deleted (enforced via RLS policies)
- **No Automatic Cleanup**: No cron jobs or scheduled tasks delete events
- **Manual Archival Only**: If archival is needed, it must be done manually or via scheduled script

### Future Enhancements

1. **Automated Archival**: Implement scheduled job for 2-year archival if needed
2. **Compression**: Consider compressing old event payloads if storage becomes an issue
3. **Partitioning**: Consider table partitioning by `created_at` for very large datasets
4. **Cold Storage**: Move archived events to cheaper storage solutions

## Compliance Considerations

### GDPR

- Events may contain personal data in payloads
- Users have right to data export (events can be included)
- Users have right to deletion (consider anonymizing events rather than deleting for audit trail)

### Industry Standards

- Financial services: Often require 7+ years retention
- Healthcare: HIPAA may require specific retention periods
- Legal services: May require indefinite retention

**Recommendation**: Consult legal/compliance team before implementing archival.

## Summary

- **Current Policy**: Keep all events forever
- **Storage**: Efficient with proper indexing
- **Performance**: Fast queries with current indexes
- **Future Option**: 2-year archival if needed
- **Compliance**: Consult legal team before changes

---

**Last Updated**: January 6, 2026  
**Next Review**: January 6, 2027 (or when events table exceeds 5 million records)
