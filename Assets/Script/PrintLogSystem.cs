using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class PrintLogSystem : Singleton<PrintLogSystem>
{
    private class PrintLog {
        public string Text;
        public float timer;
    }

    private Text uiText;
    private List<PrintLog> printLogList = new List<PrintLog>();

    protected override void Awake()
    {
        base.Awake();
    }

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    private void Start()
    {
        GameObject textObj = GameObject.Find("LogUI");
        if(textObj != null) { uiText = (Text)textObj.GetComponent<Text>(); }
    }

    // Update is called once per frame
    private void Update()
    {
        // エラーチェック
        if (uiText == null) { Debug.Log("[ERROR]: Find Failed"); }

        // 時間切れのログを削除
        RemoveExpiredLogs();

        // 表示
        PrintLogText();
    }

    // 時間切れのログを削除
    private void RemoveExpiredLogs()
    {
        // フレーム時間を引く
        for(int idx = 0; idx < printLogList.Count; idx++) 
        {
            printLogList[idx].timer -= Time.deltaTime;
        }
        // 時間が0になっている場合は削除する
        printLogList.RemoveAll(log => log.timer <= 0);
    }

    // ログの表示
    private void PrintLogText() 
    {
        uiText.text = string.Empty;
        for (int idx = 0; idx < printLogList.Count; idx++)
        {
            uiText.text += string.Format("{0}\n",printLogList[idx].Text);
        }
    }

    public void Add(string str, float time) 
    {
        if (printLogList.Count > 100)
        {
            printLogList.RemoveAt(0);
        }
        printLogList.Add(new PrintLog { Text = str, timer = time });
    }
}


public static class Print
{
    public static void Log(string str, float timer = 2.0f)
    {
        PrintLogSystem.Instance.Add(str, timer);
        Debug.Log(str);
    }
}