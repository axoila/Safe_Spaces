using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NiceQuad : MonoBehaviour {

	MeshRenderer render;
	Camera cam;

	// Use this for initialization
	void Start () {
		cam = Camera.main;
		render = GetComponent<MeshRenderer> ();

		float height = Mathf.Tan(cam.fieldOfView);
		render.transform.localScale = new Vector3 (height * cam.aspect, height, 1);
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
