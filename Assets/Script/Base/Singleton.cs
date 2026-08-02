using UnityEngine;

// 型引数 T は MonoBehaviour を継承したクラスのみ受け付ける制約（where T : MonoBehaviour）をつける
public abstract class Singleton<T> : MonoBehaviour where T : MonoBehaviour
{
    private static T instance;

    public static T Instance
    {
        get
        {
            if (instance == null)
            {
                // ヒエラルキー上から型 T に一致するオブジェクトを探す
                instance = (T)FindAnyObjectByType(typeof(T));

                if (instance == null)
                {
                    Debug.LogError($"{typeof(T)} がシーン内に見つかりません。");
                }
            }
            return instance;
        }
    }

    protected virtual void Awake()
    {
        // 念のため、Awakeのタイミングでもインスタンスを確定させておく
        if (instance == null)
        {
            instance = this as T;
        }
        else if (instance != this)
        {
            // すでに他に同じ型のインスタンスが存在する場合は重複なので破棄する
            Destroy(gameObject);
        }
    }
}