using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(Rigidbody))]
public class PlayerController : MonoBehaviour
{
    [Header("Engine & Speed")]
    [SerializeField] private float maxThrottle = 100f;
    [SerializeField] private float throttleAcceleration = 30f;
    [SerializeField] private float forwardForceMultiplier = 50f;

    [Header("Control Rotations")]
    [SerializeField] private float pitchSpeed = 50f;
    [SerializeField] private float rollSpeed = 60f;
    [SerializeField] private float yawSpeed = 30f;

    [Header("Lift (揚力)")]
    [SerializeField] private float liftMultiplier = 0.5f;

    // --- UI操作用の外部入力レシーバー ---
    [HideInInspector] public Vector2 uiVirtualJoystick; // X: Roll, Y: Pitch
    [HideInInspector] public float uiYawInput;          // -1(左) ~ +1(右)
    [HideInInspector] public float uiThrottleChange;    // +1(加速) / -1(減速)

    private Rigidbody rb;
    private float currentThrottle = 0f;

    private float pitchInput;
    private float rollInput;
    private float yawInput;

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        // --- 1. キーボード入力の取得 ---
        float kbPitch = 0f;
        float kbRoll = 0f;
        float kbYaw = 0f;
        float kbThrottle = 0f;

        var keyboard = Keyboard.current;
        if (keyboard != null)
        {
            if (keyboard.wKey.isPressed || keyboard.upArrowKey.isPressed) kbPitch += 1f;
            if (keyboard.sKey.isPressed || keyboard.downArrowKey.isPressed) kbPitch -= 1f;

            if (keyboard.dKey.isPressed || keyboard.rightArrowKey.isPressed) kbRoll += 1f;
            if (keyboard.aKey.isPressed || keyboard.leftArrowKey.isPressed) kbRoll -= 1f;

            if (keyboard.eKey.isPressed) kbYaw += 1f;
            if (keyboard.qKey.isPressed) kbYaw -= 1f;

            if (keyboard.leftShiftKey.isPressed) kbThrottle += 1f;
            if (keyboard.leftCtrlKey.isPressed) kbThrottle -= 1f;
        }
        // ゲームパッド（バーチャルスティック）の入力を取得
        if (Gamepad.current != null)
        {
            Vector2 stickInput = Gamepad.current.leftStick.ReadValue();
            // kbRoll = stickInput.x;   // 左右でロール
            kbYaw = stickInput.x;   // 左右でヨー(共通化することで操作が簡易になる)
            kbPitch = stickInput.y;  // 上下でピッチ
        }

        // --- 2. キーボードとUI入力の合算 ---
        // スティックのY軸をピッチ、X軸をロールに割り当て
        pitchInput = Mathf.Clamp(kbPitch + uiVirtualJoystick.y, -1f, 1f);
        rollInput = Mathf.Clamp(kbRoll + uiVirtualJoystick.x, -1f, 1f);
        yawInput = Mathf.Clamp(kbYaw + uiYawInput, -1f, 1f);

        float throttleChange = kbThrottle + uiThrottleChange;
        currentThrottle += throttleChange * throttleAcceleration * Time.deltaTime;
        currentThrottle = Mathf.Clamp(currentThrottle, 0f, maxThrottle);
    }

    private void FixedUpdate()
    {
        // 1. 前進力
        Vector3 forwardForce = transform.forward * currentThrottle * forwardForceMultiplier;
        rb.AddForce(forwardForce, ForceMode.Force);

        // 2. 回転力
        Vector3 torque = new Vector3(
            pitchInput * pitchSpeed,
            yawInput * yawSpeed,
            -rollInput * rollSpeed
        );
        rb.AddRelativeTorque(torque, ForceMode.Force);

        // 3. 揚力
        float forwardSpeed = Vector3.Dot(rb.linearVelocity, transform.forward);
        if (forwardSpeed > 0)
        {
            Vector3 liftForce = transform.up * (forwardSpeed * liftMultiplier * rb.mass);
            rb.AddForce(liftForce, ForceMode.Force);
        }
    }
}