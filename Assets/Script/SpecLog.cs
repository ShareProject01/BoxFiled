using UnityEngine;
using UnityEngine.UI;

public class SpecLog : MonoBehaviour
{
    // 更新間隔（秒）
    [SerializeField]
    private float updateInterval = 0.5f;

    private Text fpsText;

    private float accum = 0f;
    private int frames = 0;
    private float timeleft;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        fpsText = GetComponent<Text>();
        timeleft = updateInterval;
    }

    // Update is called once per frame
    void Update()
    {
        // タイムスケール（ポーズなど）の影響を受けないTime.unscaledDeltaTimeを使用
        timeleft -= Time.unscaledDeltaTime;
        accum += Time.unscaledDeltaTime;
        frames++;

        if (timeleft <= 0.0f)
        {
            float fps = frames / accum;
            fpsText.text = $"FPS: {fps:F1}";

            // 色の変化を付けたい場合は以下を有効化
            fpsText.color = fps >= 50 ? Color.green : (fps >= 30 ? Color.yellow : Color.red);

            timeleft = updateInterval;
            accum = 0.0f;
            frames = 0;
        }
    }
}