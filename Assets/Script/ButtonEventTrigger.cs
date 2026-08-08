using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.LowLevel;

public class ButtonEventTrigger : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
{
    // ボタンが押された瞬間に呼ばれる
    public void OnPointerDown(PointerEventData eventData)
    {
        Print.Log("ボタンが押されました！");
        if (Gamepad.current == null) return;

        // Aボタンが押された状態のステートイベントを作成してキューに送る
        var state = new GamepadState();
        state.WithButton(GamepadButton.A); // AボタンをON

        InputSystem.QueueStateEvent(Gamepad.current, state);
    }

    // ボタンが離された瞬間に呼ばれる
    public void OnPointerUp(PointerEventData eventData)
    {
        Print.Log("ボタンが離されました！");
        
        if (Gamepad.current == null) return;

        // Aボタンが押された状態のステートイベントを作成してキューに送る
        var state = new GamepadState();
        state.WithButton(GamepadButton.A, false);

        InputSystem.QueueStateEvent(Gamepad.current, state);
    }
}