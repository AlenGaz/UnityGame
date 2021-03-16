using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DetectCollisiononChar : MonoBehaviour
{
    // Start is called before the first frame update
    public bool InnerBoxColliderIsCollided = false;
    public bool HideObjectsParents { get; private set; }
    // Update is called once per frame
    private int collisionCount;
    public bool isEmpty;
    public bool TurnOffSmallCollider;

    void Start()
    {
        collisionCount = 0;
    }

    void LateUpdate()
    {
        print(collisionCount);

        StartCoroutine(ExampleCoroutine());
    }

    private void OnTriggerEnter(Collider other)
    {
        collisionCount++;
        InnerBoxColliderIsCollided = true;
        //gameObject.GetComponent<BoxCollider>().isTrigger = false;
        gameObject.GetComponentInParent<HideObjectsOnCollision>().GetComponentInChildren<BoxCollider>().isTrigger = true;
        Debug.Log("Hide big box = True");
    }



    private void OnTriggerExit(Collider other)
    {
        collisionCount--;
        //InnerBoxColliderIsCollided = false;

        //gameObject.GetComponentInParent<HideObjectsOnCollision>().GetComponentInChildren<BoxCollider>().isTrigger = false;
        //StartCoroutine(ExampleCoroutine());
        //InnerBoxColliderIsCollided = true;

    }

    bool isColliderEmpty()
    {
        TurnOffSmallCollider = true;
        return collisionCount == 0;

    }

    IEnumerator ExampleCoroutine()
    {

        //yield on a new YieldInstruction that waits for 1 seconds.
        if (isColliderEmpty())
        {
            print("in ISCOLLIDEREMPTY");
            gameObject.GetComponent<BoxCollider>().isTrigger = true;
            //gameObject.GetComponentInParent<HideObjectsOnCollision>().GetComponentInChildren<BoxCollider>().isTrigger = false;
        }
        yield return new WaitForSeconds(3);



        /*
        if (isEmpty == true)
        {

            gameObject.GetComponentInParent<HideObjectsOnCollision>().GetComponentInChildren<BoxCollider>().isTrigger = false;
            Debug.Log("Hide big box = tRUE");
            GetComponentInChildren<BoxCollider>().isTrigger = true;
        }
        else if (InnerBoxColliderIsCollided == true && isEmpty != false)
        {
            Debug.Log("Character is still under roof");
            gameObject.GetComponentInParent<HideObjectsOnCollision>().GetComponentInChildren<BoxCollider>().isTrigger = true;

        }*/


    }
}
