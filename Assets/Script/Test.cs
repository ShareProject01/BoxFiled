using UnityEngine;

public class Test : MonoBehaviour
{
    [SerializeField]
    private GameObject player;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        Print.Log("[Asahi Test] called 8");
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void EventJumpAction()
    {
        Print.Log("[Asahi Test] Jump 19");
        player.transform.Rotate(Vector3.forward * 15);
    }
}
