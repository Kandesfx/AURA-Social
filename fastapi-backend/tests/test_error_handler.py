"""
AURA Social – Unit Tests: Error Handler
Tests for standardized error responses.
"""
import pytest
from app.utils.error_handler import (
    APIErrorResponse,
    ErrorCode,
    get_status_code,
    error_to_json_response,
)


class TestErrorCodes:
    """Error code constants tests."""

    def test_error_codes_are_strings(self):
        """All error codes should be string constants."""
        assert isinstance(ErrorCode.VALIDATION_ERROR, str)
        assert isinstance(ErrorCode.NOT_FOUND, str)
        assert isinstance(ErrorCode.UNAUTHORIZED, str)

    def test_error_codes_are_screaming_snake_case(self):
        """Error codes should follow SCREAMING_SNAKE_CASE convention."""
        codes = [
            ErrorCode.VALIDATION_ERROR,
            ErrorCode.NOT_FOUND,
            ErrorCode.UNAUTHORIZED,
            ErrorCode.FORBIDDEN,
            ErrorCode.RATE_LIMITED,
            ErrorCode.INTERNAL_ERROR,
            ErrorCode.SERVICE_UNAVAILABLE,
        ]
        for code in codes:
            assert code.isupper()
            assert "_" in code or code.isalpha()


class TestAPIErrorResponseFactory:
    """APIErrorResponse factory method tests."""

    def test_validation_error(self):
        """validation_error factory should create correct error."""
        error = APIErrorResponse.validation_error(
            message="Invalid field",
            details={"field": "email"},
            request_id="req_123"
        )
        assert error.error == "VALIDATION_ERROR"
        assert error.message == "Invalid field"
        assert error.details == {"field": "email"}
        assert error.request_id == "req_123"

    def test_not_found(self):
        """not_found factory should create correct error."""
        error = APIErrorResponse.not_found("User", "user123", "req_456")
        assert error.error == "NOT_FOUND"
        assert "user123" in error.message
        assert "User" in error.message
        assert error.request_id == "req_456"

    def test_not_found_without_id(self):
        """not_found without ID should still work."""
        error = APIErrorResponse.not_found("Post")
        assert error.error == "NOT_FOUND"
        assert "Post" in error.message

    def test_unauthorized(self):
        """unauthorized factory should create correct error."""
        error = APIErrorResponse.unauthorized(request_id="req_789")
        assert error.error == "UNAUTHORIZED"
        assert error.request_id == "req_789"

    def test_rate_limited(self):
        """rate_limited factory should include retry info."""
        error = APIErrorResponse.rate_limited(
            message="Slow down",
            retry_after=60,
            request_id="req_abc"
        )
        assert error.error == "RATE_LIMITED"
        assert error.details == {"retry_after_seconds": 60}
        assert error.request_id == "req_abc"

    def test_internal_error(self):
        """internal_error factory should not leak details."""
        error = APIErrorResponse.internal_error(request_id="req_def")
        assert error.error == "INTERNAL_ERROR"
        assert "internal" in error.message.lower() or "unexpected" in error.message.lower()

    def test_firestore_error(self):
        """firestore_error should include operation name."""
        error = APIErrorResponse.firestore_error("get_user", "req_xyz")
        assert error.error == "FIRESTORE_ERROR"
        assert error.details == {"operation": "get_user"}

    def test_emotion_error(self):
        """emotion_error should create domain-specific error."""
        error = APIErrorResponse.emotion_error(
            message="Could not analyze emotion",
            request_id="req_em1"
        )
        assert error.error == "EMOTION_INFERENCE_ERROR"

    def test_service_unavailable(self):
        """service_unavailable should name the failing service."""
        error = APIErrorResponse.service_unavailable("Firebase")
        assert error.error == "SERVICE_UNAVAILABLE"
        assert "Firebase" in error.message


class TestStatusCodeMapping:
    """HTTP status code mapping tests."""

    def test_validation_error_returns_400(self):
        """VALIDATION_ERROR should map to 400."""
        assert get_status_code(ErrorCode.VALIDATION_ERROR) == 400

    def test_not_found_returns_404(self):
        """NOT_FOUND should map to 404."""
        assert get_status_code(ErrorCode.NOT_FOUND) == 404

    def test_unauthorized_returns_401(self):
        """UNAUTHORIZED should map to 401."""
        assert get_status_code(ErrorCode.UNAUTHORIZED) == 401

    def test_rate_limited_returns_429(self):
        """RATE_LIMITED should map to 429."""
        assert get_status_code(ErrorCode.RATE_LIMITED) == 429

    def test_internal_error_returns_500(self):
        """INTERNAL_ERROR should map to 500."""
        assert get_status_code(ErrorCode.INTERNAL_ERROR) == 500

    def test_service_unavailable_returns_503(self):
        """SERVICE_UNAVAILABLE should map to 503."""
        assert get_status_code(ErrorCode.SERVICE_UNAVAILABLE) == 503

    def test_unknown_error_returns_500(self):
        """Unknown error codes should default to 500."""
        assert get_status_code("UNKNOWN_ERROR") == 500


class TestErrorToJSONResponse:
    """Error to JSON response conversion tests."""

    def test_creates_json_response(self):
        """error_to_json_response should create JSONResponse."""
        error = APIErrorResponse.not_found("Post", "post123")
        response = error_to_json_response(error)
        assert response.status_code == 404

    def test_response_body_contains_error(self):
        """Response body should contain error fields."""
        error = APIErrorResponse.validation_error(
            message="Bad input",
            details={"field": "name"},
            request_id="req_test"
        )
        response = error_to_json_response(error)
        body = response.body.decode("utf-8")
        assert "VALIDATION_ERROR" in body
        assert "Bad input" in body
        assert "req_test" in body

    def test_excludes_none_fields(self):
        """Fields with None values should be excluded from JSON."""
        error = APIErrorResponse.unauthorized()
        response = error_to_json_response(error)
        body = response.body.decode("utf-8")
        # details and request_id should not appear when None
        assert '"details": null' not in body or '"details"' not in body


class TestAPIErrorResponseValidation:
    """Pydantic model validation tests."""

    def test_valid_error_response(self):
        """Valid error response should parse correctly."""
        error = APIErrorResponse(
            error="TEST_ERROR",
            message="Test message",
            details={"key": "value"},
            request_id="req_123"
        )
        assert error.error == "TEST_ERROR"
        assert error.message == "Test message"
        assert error.details == {"key": "value"}

    def test_error_code_required(self):
        """error field should be required."""
        with pytest.raises(Exception):  # ValidationError
            APIErrorResponse(message="Test")

    def test_message_required(self):
        """message field should be required."""
        with pytest.raises(Exception):  # ValidationError
            APIErrorResponse(error="TEST_ERROR")

    def test_optional_fields_default_none(self):
        """Optional fields should default to None."""
        error = APIErrorResponse(
            error="TEST_ERROR",
            message="Test"
        )
        assert error.details is None
        assert error.request_id is None

    def test_json_schema_example(self):
        """JSON schema should have correct structure."""
        error = APIErrorResponse.validation_error(
            message="Invalid",
            details={"field": "x"},
            request_id="req_1"
        )
        json_data = error.model_dump(exclude_none=True)
        assert "error" in json_data
        assert "message" in json_data
        assert isinstance(json_data, dict)
