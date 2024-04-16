using System;
using UnityEngine;

public class PosUpdate : MonoBehaviour
{
    private Material _grass;

    private void Awake()
    {
        _grass = GameObject.Find("uploads_files_3639591_Grass").transform.GetChild(0).GetComponent<Renderer>().sharedMaterial;
    }

    private void Update()
    {
        _grass.SetVector("_GlobalPos",transform.position);
    }
}