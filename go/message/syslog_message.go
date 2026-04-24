package message

import "time"

type SyslogMessage struct {
	Timestamp    time.Time `json:"timestamp"`
	Host         string    `json:"host"`
	Severity     string    `json:"severity"`
	SeverityCode int       `json:"severity_code"`
	Facility     string    `json:"facility"`
	FacilityCode int       `json:"facility_code"`
	Message      string    `json:"message"`
	RawMessage   string    `json:"raw_message"`
}

// Severity constants (syslog RFC 5424)
const (
	SeverityEmergency = 0
	SeverityAlert     = 1
	SeverityCritical  = 2
	SeverityError     = 3
	SeverityWarning   = 4
	SeverityNotice    = 5
	SeverityInfo      = 6
	SeverityDebug     = 7
)

// Facility constants
const (
	FacilityKernel     = 0
	FacilityUser       = 1
	FacilityMail       = 2
	FacilityDaemon     = 3
	FacilityAuth       = 4
	FacilitySyslog     = 5
	FacilityLpr        = 6
	FacilityNews       = 7
	FacilityUUCP       = 8
	FacilityCron       = 9
	FacilityAuthPriv   = 10
	FacilityFTP        = 11
	FacilityNTP        = 12
	FacilityLogAudit   = 13
	FacilityLogAlert   = 14
	FacilityLocal0     = 16
	FacilityLocal1     = 17
	FacilityLocal2     = 18
	FacilityLocal3     = 19
	FacilityLocal4     = 20
	FacilityLocal5     = 21
	FacilityLocal6     = 22
	FacilityLocal7     = 23
)

func SeverityToString(code int) string {
	switch code {
	case SeverityEmergency:
		return "Emergency"
	case SeverityAlert:
		return "Alert"
	case SeverityCritical:
		return "Critical"
	case SeverityError:
		return "Error"
	case SeverityWarning:
		return "Warning"
	case SeverityNotice:
		return "Notice"
	case SeverityInfo:
		return "Info"
	case SeverityDebug:
		return "Debug"
	default:
		return "Unknown"
	}
}

func FacilityToString(code int) string {
	switch code {
	case FacilityKernel:
		return "Kernel"
	case FacilityUser:
		return "User"
	case FacilityMail:
		return "Mail"
	case FacilityDaemon:
		return "Daemon"
	case FacilityAuth:
		return "Auth"
	case FacilitySyslog:
		return "Syslog"
	case FacilityLpr:
		return "Lpr"
	case FacilityNews:
		return "News"
	case FacilityUUCP:
		return "UUCP"
	case FacilityCron:
		return "Cron"
	case FacilityAuthPriv:
		return "AuthPriv"
	case FacilityFTP:
		return "FTP"
	case FacilityNTP:
		return "NTP"
	case FacilityLogAudit:
		return "LogAudit"
	case FacilityLogAlert:
		return "LogAlert"
	case FacilityLocal0:
		return "Local0"
	case FacilityLocal1:
		return "Local1"
	case FacilityLocal2:
		return "Local2"
	case FacilityLocal3:
		return "Local3"
	case FacilityLocal4:
		return "Local4"
	case FacilityLocal5:
		return "Local5"
	case FacilityLocal6:
		return "Local6"
	case FacilityLocal7:
		return "Local7"
	default:
		return "Unknown"
	}
}
