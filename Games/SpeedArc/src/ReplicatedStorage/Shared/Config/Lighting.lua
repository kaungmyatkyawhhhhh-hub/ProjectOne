-- Lighting presets per area (Lighting note). LightingController applies the area you are in.
return {
	-- 28 Oct candy look: a high sunny midday, bright soft shadows, extra colour
	Hub = {
		ClockTime = 13.5,
		GeographicLatitude = 30,
		Brightness = 2.2,
		Ambient = Color3.fromHex("#6E7BA0"),
		OutdoorAmbient = Color3.fromHex("#8F9EC4"),
		EnvironmentDiffuseScale = 0.5,
		EnvironmentSpecularScale = 0.15,
		ExposureCompensation = -0.15,
		ColorCorrection = { Contrast = 0.14, Saturation = 0.22, Brightness = 0, TintColor = Color3.fromHex("#FFFFFF") },
		Bloom = { Intensity = 0.18, Size = 20, Threshold = 2.2 },
		SunRays = { Intensity = 0.02, Spread = 0.5 },
		Atmosphere = { Density = 0.14, Offset = 0.05, Color = Color3.fromHex("#CFE6FF"), Decay = Color3.fromHex("#9EC3EE"), Glare = 0, Haze = 0.4 },
		Clouds = { Cover = 0.55, Density = 0.6, Color = Color3.fromHex("#FFFFFF") },
	},
	Park = {
		ClockTime = 9.0,
		GeographicLatitude = 30,
		Brightness = 2.6,
		Ambient = Color3.fromHex("#7486A6"),
		OutdoorAmbient = Color3.fromHex("#9AAED0"),
		EnvironmentDiffuseScale = 0.6,
		EnvironmentSpecularScale = 0.25,
		ExposureCompensation = 0.15,
		ColorCorrection = { Contrast = 0.06, Saturation = 0.15, Brightness = 0.03, TintColor = Color3.fromHex("#F4F8FF") },
		Bloom = { Intensity = 0.35, Size = 24, Threshold = 1.5 },
		SunRays = { Intensity = 0.05, Spread = 0.6 },
		Atmosphere = { Density = 0.3, Offset = 0.2, Color = Color3.fromHex("#BFD8FF"), Decay = Color3.fromHex("#9FB8DD"), Glare = 0.15, Haze = 1.2 },
	},
	Stadium = {
		ClockTime = 17.3, -- golden hour (18.0 was already dusk with the moon up)
		GeographicLatitude = 35,
		Brightness = 2.0,
		Ambient = Color3.fromHex("#5A6484"),
		OutdoorAmbient = Color3.fromHex("#7C7FA0"),
		EnvironmentDiffuseScale = 0.55,
		EnvironmentSpecularScale = 0.3,
		ExposureCompensation = 0.05,
		ColorCorrection = { Contrast = 0.12, Saturation = 0.1, Brightness = 0.0, TintColor = Color3.fromHex("#FFEBD6") },
		Bloom = { Intensity = 0.55, Size = 28, Threshold = 1.3 },
		SunRays = { Intensity = 0.08, Spread = 0.7 },
		Atmosphere = { Density = 0.32, Offset = 0.1, Color = Color3.fromHex("#F2C7A0"), Decay = Color3.fromHex("#6A6F99"), Glare = 0.4, Haze = 1.4 },
	},
	-- Low graphics (quality 1-3): no Bloom / SunRays, lighter atmosphere
	LowQualityLevel = 3,
}
